ST=crystal build --no-debug --release -p --static --link-flags '-s -w'
DYN=crystal build --no-debug --release -p

all:
	$(DYN) src/web.cr
	$(DYN) src/grab.cr

st:
	$(ST) src/web.cr
	$(ST) src/grab.cr
