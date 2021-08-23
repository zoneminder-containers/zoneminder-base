import re
from shutil import copyfile
from os import path
from typing import Optional, List, Pattern, Tuple


class PackageNotFound(Exception):
    pass


def locate_distro() -> str:
    """Return base path for control/compat files."""
    if path.isfile("distros/ubuntu2004/control"):
        control_location = "distros/ubuntu2004"
    else:
        control_location = "distros/ubuntu1604"
    return control_location


def load_control() -> List[Optional[str]]:
    control_programs = []
    base_location = locate_distro()
    control_location = path.join(base_location, "control")
    with open(control_location, "r") as file_obj:
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


def remove_duplicate(input_str: str, duplicated_pattern: Pattern, replace: str = "") -> str:
    """Remove a duplicated pattern in a string."""
    while re.search(duplicated_pattern, input_str):
        input_str = re.sub(duplicated_pattern, replace, input_str)
    return input_str


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


def get_package(control_programs: List[str], package_name: str) -> str:
    """Get named package from control program list."""
    for control_program in control_programs:
        item = re.sub(r'(^Package: )', '', get_value(control_program, "Package").rstrip())
        if item == package_name:
            return control_program
    raise PackageNotFound


control_pkg = get_package(load_control(), "zoneminder")

with open("zoneminder_control", "w") as file_obj:
    file_obj.write(control_pkg)

# Used as default for equivs-build template due to bug
copyfile(path.join(locate_distro(), "compat"), "zoneminder_compat")
