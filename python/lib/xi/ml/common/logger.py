# encoding: utf-8


import sys
import logging


# Module: handle the predefined and updatable loggers

ROOT = 'xi.ml'
PATH = '.'
FNAME = 'python-xi-ml'
loggers = {}

def create(name):
    """Create a new logger with the class name and return it"""

    if not name.startswith(ROOT):
        return None

    if ROOT not in loggers:
        create_root()

    if name in loggers:
        return loggers[name]

    clogger = logging.getLogger(name)
    clogger.setLevel(loggers.get(ROOT).getEffectiveLevel())
    clogger.handlers = list(loggers.get(ROOT).handlers)
    clogger.propagate = False

    # add to dictionary
    loggers[name] = clogger

    return clogger

def global_level(level):
    """Change the logging level of all existing loggers"""

    for clogger in loggers.values():
        clogger.setLevel(level)

def copy_config(rlogger):
    """Copy the configuration of reference logger onto all existing loggers"""

    if not isinstance(rlogger, logging.Logger):
        return

    for clogger in loggers:
        clogger.setLevel(rlogger.level)
        clogger.handlers = list(rlogger.handlers)


def create_root():
    """Create the root logger: every logger will be using his configuration"""

    # create root if it does not already exist
    if ROOT not in loggers:

        # log formatter
        log_formatter = logging.Formatter(
            '[%(name)s] [%(asctime)s] %(levelname)s : %(message)s')

        # file handler - if needed
        file_handler = logging.FileHandler(
            "{0}/{1}.log".format(PATH, FNAME))
        file_handler.setFormatter(log_formatter)

        # console handler
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setFormatter(log_formatter)

        root_logger = logging.getLogger(ROOT)
        root_logger.__name__ = ROOT
        root_logger.addHandler(console_handler)
        root_logger.setLevel(logging.INFO)
        root_logger.propagate = False

        # add to dictionary
        loggers[ROOT] = root_logger

    return loggers[ROOT]

# create ROOT logger
create_root()
