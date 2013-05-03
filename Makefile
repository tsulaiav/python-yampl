all:
	python setup.py build_ext install

.PHONY:
clean:
	rm -rf *.so *.cpp build
