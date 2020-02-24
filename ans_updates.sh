read ans
echo $ans
if [ "$ans" = "y" ];then
	pacman -Syu
fi
