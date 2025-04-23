# fixexp
# load the function globally when script is called

function fixexp {
    ro "restarting explorer... " -n
    stop-process -name explorer -force
    ro "|@s|done!"
}
