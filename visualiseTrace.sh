make TFLAG=-t test | awk -F@ '
{
  if ($3 > 46900) print $0
}
' > OUTN

for i in 0 1 2
do
  fgrep "]@$i" < OUTN | sed -e 's/^.*stdcore.0.//' | grep -v -e '-P-.* out' | grep -v -e '-P-.* in'  | fgrep -v 'Event caus' | sed 's/[^:]*: //' | awk -F@ '
BEGIN {
  last = 46959;
  this = '$i';
  if (this == 1) OUTCNT = -5
  if (this == 0) nextt = 2;
  if (this == 1) nextt = 3;
  if (this == 2) nextt = 1;
}
/^in/{
  last++;
  while($2 > last) printf("@%d\n", last++);
  print "Q" this "." (++INCNT) " " $0
  next;
}
/^out/{
  last++;
  while($2 > last) printf("@%d\n", last++);
  print "Q" nextt "." (++OUTCNT) " " $0
  next;
}
{
  last++;
  while($2 > last) printf("@%d\n", last++);
  print $0
  next;
}
END {
  while(last < 50100) printf("@%d\n", last++);
}
' > OUT$i
done
join -t@ -1 2 -2 2 OUT0 OUT2 | join -t@ -1 1 -2 2 - OUT1 | tr '@' '	' | expand -6,56,106,156
rm OUT0 OUT1 OUT2 OUTN
