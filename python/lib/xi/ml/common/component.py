# encoding: utf-8


from xi.ml.common import logger
from xi.ml.common import Timer


class Component:
    """The class with common logger & timer instance variables"""

    def __init__(self):
        self.logger = logger.create(self.__module__)
        self.timer = Timer()
