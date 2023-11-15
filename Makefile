dep.pre-commit:
	which pre-commit &> /dev/null || python3 -m pip install pre-commit
	pre-commit install

deps: dep.pre-commit

bootstrap: deps

format:
	pre-commit run --all-files
