syntax:
	python3 -m compileall .

pylint:
	if [ -d "lib/xi/ml" ]; then python3 -m pylint --rcfile=.pylintrc lib/xi/ml; fi

pytest:
	if [ -d "test" ]; then python3 setup.py pytest; fi

build:
	python3 setup.py build

clean:
	find . -name '*.eggs' -type d -prune -exec rm -r {} \;
	find . -name '*.egg' -type d -prune -exec rm -r {} \;
	find . -name '*.egg-info' -type d -prune -exec rm -r {} \;
	find . -name '__pycache__' -type d -prune -exec rm -r {} \;
	find . -name '*.cache' -type d -prune -exec rm -r {} \;
	find . -name '*.py[co]' -type f -exec rm {} \;
	find . -name '*.log' -type f -exec rm {} \;
	find . -name '*.egg' -type f -exec rm {} \;
	rm -rf ./build \;
	rm -rf ./dist \;
	rm -rf ./eggs \;


dev: build
	python3 setup.py develop

install:
	python3 setup.py install

wheel:
	python3 setup.py bdist_wheel

register:
	python3 setup.py register -r localrep

upload: build install wheel register
	twine upload dist/* -r localrep


local-install:
	pip install -e .

