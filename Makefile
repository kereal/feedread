STATIC=crystal build --no-debug --release -p --static --link-flags '-s -w' -t
DYNAMIC=crystal build --no-debug --release -p

all: web grab

web:
	$(STATIC) src/web.cr

grab:
	$(STATIC) src/grab.cr

alldyn:
	$(DYNAMIC) src/web.cr
	$(DYNAMIC) src/grab.cr
