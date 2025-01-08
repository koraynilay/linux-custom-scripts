var s = 0;
for(i of document.getElementsByClassName("text-center")) {
    c = i.innerHTML;
    const re = /^([0-9]+\.?[0-9]) ([TGMK])iB$/;
    k = c.match(re)
    if(k) {
        var m = 1
        switch(k[2]) {
            case 'T': m = 1000000000;break
            case 'G': m = 1000000;break
            case 'M': m = 1000;break
            case 'K': m = 1;break
        }
        s+=k[1]*m;
    }
}
console.log(s/1000000000)
