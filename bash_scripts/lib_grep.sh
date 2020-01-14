# Grep that doesn't exit error when nothing is matched. 
# As in: https://stackoverflow.com/questions/6550484/prevent-grep-returning-an-error-when-input-doesnt-match

function grep { 
    env grep "$@" || test $? = 1; 
}