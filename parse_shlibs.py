import re


with open("resolved.txt", "r") as file_obj:
    for line in file_obj:
        if line.startswith("shlibs:Depends="):
            shlibs_str = re.sub(r"(^shlibs:Depends=)", "", line)
            break

shlibs = shlibs_str.split(",")

shlibs = [
    re.sub(r'(\(.*\))', "", lib).strip() for lib in shlibs
]

with open("resolved_installable.txt", "w") as file_obj:
    for lib in shlibs:
        file_obj.write(lib + "\n")
