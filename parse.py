import re
from typing import Optional, List, Pattern, Tuple


class AlternativeNotDefined(Exception):
    pass


def load_control() -> List[Optional[str]]:
    control_programs = []
    with open("distros/ubuntu2004/control", "r") as file_obj:
        program = ""
        pkg_found = False
        for line in file_obj:
            if line.startswith("#"):
                continue
            if "Package: " in line:
                if pkg_found:
                    control_programs.append(program)
                    program = ""
                else:
                    pkg_found = True
            program += line
        # append last program
        control_programs.append(program)
    return control_programs


def get_alternatives(pkg_list: list, preferred_alternative: list = None) -> Tuple[list, List[list]]:
    standard_packages = []
    alternatives = []
    for dep in pkg_list:
        if "|" in dep:
            pkgs = dep.split("|")
            found = False
            if preferred_alternative:
                for pkg in pkgs:
                    if pkg in preferred_alternative:
                        found = True
                        alternatives.append([pkg])
            if not found:
                raise AlternativeNotDefined(f"Alternative for pkgs not found: {dep}")
        else:
            standard_packages.append(dep)
    return standard_packages, alternatives


def remove_duplicate(input_str: str, duplicated_pattern: Pattern, replace: str = "") -> str:
    """Remove a duplicated pattern in a string."""
    while re.search(duplicated_pattern, input_str):
        input_str = re.sub(duplicated_pattern, replace, input_str)
    return input_str


def clean_pkg_list(unclean_pkg_list: str) -> List[str]:
    """Strips out definition, spaces, new lines, hurds, and variables."""
    strip_patterns = [
        re.compile(r"(\${)(.*?)(})"),  # Strip variables
        re.compile(r"(\()(.*?)(\))"),  # Strip version
        re.compile(r"(\[)(.*?)(\])"),  # Strip hurds
    ]
    for pattern in strip_patterns:
        unclean_pkg_list = re.sub(pattern, "", unclean_pkg_list)
    # Replace definition by replacing the first match of :
    unclean_pkg_list = re.sub(r"(.*?)(:)", "", unclean_pkg_list, 1)
    unclean_pkg_list = remove_duplicate(unclean_pkg_list, re.compile(r"  "))
    unclean_pkg_list = remove_duplicate(unclean_pkg_list, re.compile(r",,"))
    unclean_pkg_list = re.sub(" , ", ", ", unclean_pkg_list)
    unclean_pkg_list = re.sub(" ", "", unclean_pkg_list)
    unclean_pkg_list = re.sub(",", "\n", unclean_pkg_list)
    unclean_pkg_list = remove_duplicate(unclean_pkg_list, re.compile(r"\n\n"), "\n")
    unclean_pkg_list = unclean_pkg_list.strip(" \n")
    clean = unclean_pkg_list.split("\n")
    clean.sort()
    return clean


def get_value(pkg_info: str, pkg_key: str) -> Optional[str]:
    """Return value of key. Cannot have duplicate value in string passed in."""
    lines = pkg_info.split('\n')
    key_start = None  # type: Optional[int]
    key_end = None  # type: Optional[int]
    for line_num in range(len(lines)):
        if (line := lines[line_num]).startswith(pkg_key):
            key_start = line_num
        elif key_start and re.search(r"(^(?! ).*?)(:)", line):
            # Do not want to include this line but use it as a stopper
            key_end = line_num - 1
            break
    if key_start and key_end:
        key_value = ""
        for line_num in range(key_start, key_end + 1):
            key_value += lines[line_num] + "\n"
        return key_value
    else:
        return None


def flatten_list(input_list: list) -> list:
    """Flatten a single layer list."""
    output = []
    for inner_list in input_list:
        for value in inner_list:
            output.append(value)
    return output


preferred_alternative = [
    "liblivemedia64",
    "libvncclient1",
    "mariadb-client",
    "php-apcu-bc",
    "rsyslog",
    "libjpeg62-turbo-dev",
    "default-libmysqlclient-dev",
]

control_pkg = get_value(load_control()[0], "Depends")
control_pkg = clean_pkg_list(control_pkg)
standard, alternative = get_alternatives(control_pkg, preferred_alternative)
alternative = flatten_list(alternative)
all_runtime = standard
all_runtime.extend(alternative)

control_pkg = get_value(load_control()[0], "Build-Depends")
control_pkg = clean_pkg_list(control_pkg)
standard, alternative = get_alternatives(control_pkg, preferred_alternative)
alternative = flatten_list(alternative)
all_build = standard
all_build.extend(alternative)

with open("runtime.txt", "w") as file_obj:
    for pkg in all_runtime:
        file_obj.write(pkg + "\n")

with open("build.txt", "w") as file_obj:
    for pkg in all_build:
        file_obj.write(pkg + "\n")
