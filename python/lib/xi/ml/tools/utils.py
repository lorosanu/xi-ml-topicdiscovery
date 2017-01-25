# -*-coding:utf-8 -*


import os.path
from xi.ml.error import ConfigError


# Module: execute useful file and folder commands

def value_checkup(input_file):
    """Convert None value to empty string"""

    if input_file is None:
        return ''
    return input_file

def filename(input_file):
    """Static method to recover file name with extension"""

    input_file = value_checkup(input_file)
    return os.path.basename(input_file)

def basename(input_file):
    """Static method to recover file basename"""

    input_file = value_checkup(input_file)
    return os.path.basename(os.path.splitext(input_file)[0])

def dirname(input_file):
    """Static method to recover file dirname"""

    input_file = value_checkup(input_file)
    return os.path.dirname(input_file)

def extname(input_file):
    """Static method to recover file extension"""

    input_file = value_checkup(input_file)
    return os.path.splitext(input_file)[1]

def path_without_ext(input_file):
    """Static method to recover path without extension"""

    input_file = value_checkup(input_file)
    return os.path.join(dirname(input_file), basename(input_file))

def has_extension(input_file, ext):
    """Static method to check right file extension"""

    input_file = value_checkup(input_file)

    if input_file == '':
        return False

    if extname(input_file) == ext:
        return True

    return False

def change_extension(input_file, ext):
    """Static method to change file extension into 'ext'"""

    input_file = value_checkup(input_file)

    if input_file == '':
        return ''

    return os.path.splitext(input_file)[0] + '.' + ext

def check_file_readable(input_file):
    """Static method to check file existance"""

    input_file = value_checkup(input_file)

    if not os.path.exists(input_file):
        raise ConfigError(
            "File '{}' is missing or not readable".format(input_file))

def check_folder_readable(input_folder):
    """Static method to check folder existance"""

    input_folder = value_checkup(input_folder)

    if not os.path.isdir(input_folder):
        raise ConfigError("Folder '{}' is missing".format(input_folder))

def create_folder(output):
    """Static method to create folder path"""

    output = value_checkup(output)

    if output == '':
        return

    if not os.path.isdir(output):
        os.makedirs(output)

def create_path(output):
    """Static method to create file path"""

    output = value_checkup(output)

    if output == '' or os.path.dirname(output) == '':
        return

    if not os.path.isdir(os.path.dirname(output)):
        os.makedirs(os.path.dirname(output))

def check_equal_docnumbers(input_file1, input_file2):
    """Static method to check if two files have the same number of documents"""

    input_file1 = value_checkup(input_file1)
    input_file2 = value_checkup(input_file2)

    if input_file1 == '' or input_file2 == '':
        return False

    if os.path.exists(input_file1) and os.path.exists(input_file2):
        nlines_1 = sum(1 for line in open(input_file1))
        nlines_2 = sum(1 for line in open(input_file2))
        return nlines_1 == nlines_2

    return False
