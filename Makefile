tag:
	git tag v1 $( git rev-parse HEAD ) --force
	git push origin --tags --force
