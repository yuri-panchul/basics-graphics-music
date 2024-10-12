# :wrench: TODO:

## Using  OSS CAD Suite for Windows for lab works 

1. Extract OSS CAD Suit into C:\oss-cad-suite
2. Create environment.sh in the C:\oss-cad-suite] directory 

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
3. In git bash run
   ```
   source /c/oss-cad-suite/environment.sh
   ```
