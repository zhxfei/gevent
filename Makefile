# This file is renamed to "Makefile.ext" in release tarballs so that setup.py won't try to
# run it.  If you want setup.py to run "make" automatically, rename it back to "Makefile".

PYTHON ?= python${TRAVIS_PYTHON_VERSION}
CYTHON ?= cython

all: gevent/gevent.corecext.c gevent/gevent.ares.c gevent/gevent._semaphore.c gevent/gevent._util.c

gevent/gevent.corecext.c: gevent/core.ppyx gevent/libev.pxd
	$(PYTHON) util/cythonpp.py -o gevent.corecext.c gevent/core.ppyx
	echo                          >> gevent.corecext.c
	echo '#include "callbacks.c"' >> gevent.corecext.c
	mv gevent.corecext.* gevent/

gevent/gevent.ares.c: gevent/ares.pyx gevent/*.pxd
	$(CYTHON) -o gevent.ares.c gevent/ares.pyx
	mv gevent.ares.* gevent/

gevent/gevent._semaphore.c: gevent/_semaphore.py
	$(CYTHON) -o gevent._semaphore.c gevent/_semaphore.py
	mv gevent._semaphore.* gevent/

gevent/gevent._util.c: gevent/_util.pyx
	$(CYTHON) -o gevent._util.c gevent/_util.pyx
	mv gevent._util.* gevent/

clean:
	rm -f gevent.core.c gevent.core.h core.pyx gevent/gevent.core.c gevent/gevent.core.h gevent/core.pyx
	rm -f gevent.corecext.c gevent.corecext.h gevent/gevent.corecext.c gevent/gevent.corecext.h
	rm -f gevent.ares.c gevent.ares.h gevent/gevent.ares.c gevent/gevent.ares.h
	rm -f gevent._semaphore.c gevent._semaphore.h gevent/gevent._semaphore.c gevent/gevent._semaphore.h
	rm -f gevent._util.c gevent._util.h gevent/gevent._util.c gevent/gevent._util.h

doc:
	cd doc && PYTHONPATH=.. make html

whitespace:
	! find . -not -path "./.git/*" -not -path "./build/*" -not -path "./libev/*" -not -path "./c-ares/*" -not -path "./doc/_build/*" -not -path "./doc/mytheme/static/*" -type f | xargs egrep -l " $$"

pep8:
	${PYTHON} `which pep8` .

pyflakes:
	${PYTHON} util/pyflakes.py

lint: whitespace pep8 pyflakes

travistest:
	which ${PYTHON}
	${PYTHON} --version

	${PYTHON} -c 'import greenlet; print(greenlet, greenlet.__version__)'

	${PYTHON} setup.py install
	make bench

	cd greentest && GEVENT_RESOLVER=thread ${PYTHON} testrunner.py --config ../known_failures.py
	cd greentest && GEVENT_RESOLVER=ares GEVENTARES_SERVERS=8.8.8.8 ${PYTHON} testrunner.py --config ../known_failures.py --ignore tests_that_dont_use_resolver.txt
	cd greentest && GEVENT_FILE=thread ${PYTHON} testrunner.py --config ../known_failures.py `grep -l subprocess test_*.py`

toxtest:
	cd greentest && GEVENT_RESOLVER=thread python testrunner.py --config ../known_failures.py

fulltoxtest:
	cd greentest && GEVENT_RESOLVER=thread python testrunner.py --config ../known_failures.py
	cd greentest && GEVENT_RESOLVER=ares GEVENTARES_SERVERS=8.8.8.8 python testrunner.py --config ../known_failures.py --ignore tests_that_dont_use_resolver.txt
	cd greentest && GEVENT_FILE=thread python testrunner.py --config ../known_failures.py `grep -l subprocess test_*.py`

bench:
	${PYTHON} greentest/bench_sendall.py

travis_pypy:
	# no need to repeat linters here
	which ${PYTHON}
	${PYTHON} --version
	${PYTHON} setup.py install
	make bench
	cd greentest && ${PYTHON} testrunner.py --config ../known_failures.py

travis_cpython:
	pip install cython greenlet

	make travistest



.PHONY: clean all doc pep8 whitespace pyflakes lint travistest travis
