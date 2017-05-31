# -*-coding:utf-8 -*


import time
from xi.ml.common import logger


class Timer:
    """Class logging execution times"""

    def __init__(self):
        """Initialize the logger, the start time and the elapsed time"""

        self.logger = logger.create(self.__module__)
        self.start_time = 0
        self.elapsed_time = 0

    def start_timer(self):
        """Start the timer"""

        self.start_time = time.time()

    def stop_timer(self, msg):
        """Stop the timer and display the elapsed time in number of seconds"""

        self.elapsed_time = time.time() - self.start_time
        self.logger.info("{} in {:.3f} seconds".format(msg, self.elapsed_time))
