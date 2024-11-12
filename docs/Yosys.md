## Using  OSS CAD Suite for Windows for lab works

1. Download windows version **OSS CAD Suite** oss-cad-suite-windows-x64-xxxxxx.exe
 from the https://github.com/YosysHQ/oss-cad-suite-build/releases
2. Put  **OSS CAD Suite** into *C:\oss-cad-suite* directory
3. Create *environment.sh* in the *C:\oss-cad-suite* directory

   ```
   export YOSYSHQ_ROOT=/c/oss-cad-suite/
   export SSL_CERT_FILE=${YOSYSHQ_ROOT}etc/cacert.pem

   export PATH=${YOSYSHQ_ROOT}bin:${YOSYSHQ_ROOT}lib:$PATH
   export PYTHON_EXECUTABLE=${YOSYSHQ_ROOT}lib/python3.exe
   export QT_PLUGIN_PATH=${YOSYSHQ_ROOT}lib/qt5/plugins
   export QT_LOGGING_RULES=*=false

   export GTK_EXE_PREFIX=$YOSYSHQ_ROOT
   export GTK_DATA_PREFIX=$YOSYSHQ_ROOT
   export GDK_PIXBUF_MODULEDIR=${YOSYSHQ_ROOT}lib/gdk-pixbuf-2.0/2.10.0/loaders
   export GDK_PIXBUF_MODULE_FILE=${YOSYSHQ_ROOT}lib/gdk-pixbuf-2.0/2.10.0/loaders.cache
   gdk-pixbuf-query-loaders.exe --update-cache

   export OPENFPGALOADER_SOJ_DIR=${YOSYSHQ_ROOT}share/openFPGALoader
   ```
4. Before runing scripts in the **Git bash** run
   ```
   source /c/oss-cad-suite/environment.sh
   ```
**NOTE:** If you try to run yosys inside **Git bash** you can get
   ```
    /----------------------------------------------------------------------------\
    |  yosys -- Yosys Open SYnthesis Suite                                       |
    |  Copyright (C) 2012 - 2024  Claire Xenia Wolf <claire@yosyshq.com>         |
    |  Distributed under an ISC-like license, type "license" to see terms        |
    \----------------------------------------------------------------------------/
    Yosys 0.45+217 (git sha1 408597b47, x86_64-w64-mingw32-g++ 13.2.1 -O3)
   Segmentation fault
   ```
It is not a problem, all scripts works correctly
