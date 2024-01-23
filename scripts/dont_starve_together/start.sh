case "$(uname -m)" in
    x86_64)
        echo "Use bin64"
        cd "$PWD"/bin64 || exit
        ./dontstarve_dedicated_server_nullrenderer_x64
        ;;
    *)
        echo "Use bin"
        cd "$PWD"/bin || exit
        ./dontstarve_dedicated_server_nullrenderer_x64
        ;;
esac
