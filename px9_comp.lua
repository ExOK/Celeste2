-- px9 compress
-- by zep

-- x0,y0 where to read from
-- w,h   image width,height
-- dest  address to store
-- vget  read function (x,y)

function 
	px9_comp(x0,y0,w,h,dest,vget)
	
		local dest0=dest
		local bit=1 
		local byte=0
	
		local function vlist_val(l, val)
			-- find positon
			for i=1,#l do
				if l[i] == val then
					-- jump to top
					for j=i,2,-1 do
						l[j]=l[j-1]
					end
					l[1] = val
					return i
				end
			end
		end
	
		function putbit(bval)
			if (bval) byte+=bit 
			poke(dest, byte) bit<<=1
			if (bit==256) then
				bit=1 byte=0
				dest += 1
			end
		end
	
		function putval(val, bits)
			for i=0,bits-1 do
				putbit(val&1<<i > 0)
			end
		end
	
		function putnum(val)
			local bits = 0
			repeat
				bits += 1
				local mx=(1<<bits)-1
				local vv=min(val,mx)
				putval(vv,bits)
				val -= vv
			until vv<mx
		end
	
	
		-- first_used
	
		local el={}
		local found={}
		local highest=0
		for y=y0,y0+h-1 do
			for x=x0,x0+w-1 do
				c=vget(x,y)
				if not found[c] then
					found[c]=true
					add(el,c)
					highest=max(highest,c)
				end
			end
		end
	
		-- header
	
		local bits=1
		while highest >= 1<<bits do
			bits+=1
		end
	
		putnum(w-1)
		putnum(h-1)
		putnum(bits-1)
		putnum(#el-1)
		for i=1,#el do
			putval(el[i],bits)
		end
	
	
		-- data
	
		local pr={} -- predictions
	
		local dat={}
	
		for y=y0,y0+h-1 do
			for x=x0,x0+w-1 do
				local v=vget(x,y)  
	
				local a=0
				if (y>y0) a+=vget(x,y-1)
	
				-- create vlist if needed
				local l=pr[a]
				if not l then
					l={}
					for i=1,#el do
						l[i]=el[i]
					end
					pr[a]=l
				end
	
				-- add to vlist
				add(dat,vlist_val(l,v))
			   
				-- and to running list
				vlist_val(el, v)
			end
		end
	
		-- write
		-- store bit-0 as runtime len
		-- start of each run
	
		local nopredict
		local pos=1
	
		while pos <= #dat do
			-- count length
			local pos0=pos
	
			if nopredict then
				while dat[pos]!=1 and pos<=#dat do
					pos+=1
				end
			else
				while dat[pos]==1 and pos<=#dat do
					pos+=1
				end
			end
	
			local splen = pos-pos0
			putnum(splen-1)
	
			if nopredict then
				-- values will all be >= 2
				while pos0 < pos do
					putnum(dat[pos0]-2)
					pos0+=1
				end
			end
	
			nopredict=not nopredict
		end
	
		if (bit!=1) dest+=1 -- flush
	
		return dest-dest0
	end
	