    cls()
    print("compressing..",5)
    flip()

    w=112 h=16
    raw_size=(w*h+1)/2 -- bytes

    -- compress to map data part 2

    clen = px9_comp(
        0,0,
        w,h,
        0x2000 + 0x800,
        mget)

    cstore() -- save to cart

    print("")
    print("compressed spritesheet to map",6)
    ratio=tostr(clen/raw_size*100)
    print("bytes: "
        ..clen.." / "..raw_size
        .." ("..sub(ratio,1,4).."%)"
        ,12)