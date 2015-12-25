export JAVA_HOME=/usr/local/java8
for cls in `ls *.class`; do
  /usr/local/java8/bin/javap $cls | grep 'public static void main(java.lang.String\[\])' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    /usr/local/java8/bin/java $@ ${cls%.*}
    exit $?
  fi
done
echo "The program compiled successfully, but main class was not found." >&2
echo "Main class should contain method: public static void main (String[] args)." >&2
exit 1
