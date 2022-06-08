ST=crystal build --no-debug --release -p --static --link-flags '-s -w' -t
DYN=crystal build --no-debug --release -p

all:
	$(ST) src/web.cr
	$(ST) src/grab.cr

alldyn:
	$(DYN) src/web.cr
	$(DYN) src/grab.cr

web:
	$(ST) src/web.cr

grab:
	$(ST) src/grab.cr

