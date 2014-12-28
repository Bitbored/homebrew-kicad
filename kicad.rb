require "formula"

# Documentation: https://github.com/Homebrew/homebrew/blob/master/share/doc/homebrew/Formula-Cookbook.md
#                /usr/local/Library/Contributions/example-formula.rb
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!

class Kicad < Formula
  homepage "http://kicad-pcb.org"
  head "https://github.com/KiCad/kicad-source-mirror.git"

  resource 'wxPython' do
    url "http://downloads.sourceforge.net/project/wxpython/wxPython/3.0.2.0/wxPython-src-3.0.2.0.tar.bz2"
    sha1 "5053f3fa04f4eb3a9d4bfd762d963deb7fa46866"
  end
  
  depends_on "cmake" => :build
  depends_on "boost" 
  depends_on "cairo"
  depends_on "swig"
  depends_on "pkgconfig"
  depends_on "libpng"
  depends_on "pcre"  

  def install
    kicad_path = buildpath

    resource("wxPython").stage do
      (buildpath/"wx").install Dir["*"]
      #system "cd #{buildpath}"
      cd buildpath/"wx" do
        system "patch", "-p0", "-i#{kicad_path}/patches/wxwidgets-3.0.0_macosx.patch"
        system "patch", "-p0", "-i#{kicad_path}/patches/wxwidgets-3.0.0_macosx_bug_15908.patch"
        system "patch", "-p0", "-i#{kicad_path}/patches/wxwidgets-3.0.0_macosx_soname.patch"
        #if MacOS.version >= :yosemite
        system "curl https://gist.githubusercontent.com/metacollin/c138f049e41d9cc42ef9/raw/0174436d883d5eebdbad18a8d98e8d318df59725/patch | patch -p0"
        #end
        ENV['CC'] = "/usr/bin/clang"
        ENV['CXX'] = "/usr/bin/clang++"
        args = %W[
          --prefix=#{kicad_path}/wx-bin 
          --with-opengl 
          --enable-aui 
          --enable-utf8 
          --enable-html 
          --enable-stl 
          --with-libjpeg=builtin 
          --with-libpng=builtin 
          --with-regex=builtin 
          --with-libtiff=builtin 
          --with-zlib=builtin 
          --with-expat=builtin 
          --without-liblzma 
          --with-macosx-version-min=#{MacOS.version} 
          --enable-universal-binary=i386,x86_64
          CC=clang 
          CXX=clang++
          ]
        system "mkdir", "wx-build"
        cd "wx-build" do
        system "#{kicad_path}/wx/configure", *args
        system "make", "-j4"
        system "make", "install"
      end
        #system "sleep 1000"
        cd "wxPython" do
          ENV['CC'] = "/usr/bin/clang"
          ENV['CXX'] = "/usr/bin/clang++"
          ENV.append_to_cflags "-stdlib=libc++"
          system "/usr/bin/python", "setup.py", "build_ext", "WX_CONFIG=#{kicad_path}/wx-bin/bin/wx-config", "UNICODE=1", "WXPORT=osx_cocoa", "BUILD_BASE=#{kicad_path}/wx/wx-build"
          system "/usr/bin/python", "setup.py", "install", "--prefix=#{kicad_path}/wx-bin", "WX_CONFIG=#{kicad_path}/wx-bin/bin/wx-config", "UNICODE=1", "WXPORT=osx_cocoa", "BUILD_BASE=#{kicad_path}/wx/wx-build"
        end
      end
    end

    #system "curl -Lo wxPython.tar.bz2 http://downloads.sourceforge.net/project/wxpython/wxPython/3.0.2.0/wxPython-src-3.0.2.0.tar.bz2"
    #system "tar -zxf wxPython.tar.bz2"
    #system "sh scripts/osx_build_wx.sh wxPython-src-3.0.2.0 wx-bin ./ #{MacOS.version} \"-j8\""

    mkdir "build" do
#    cd "build" do
        ENV["CMAKE_C_COMPILER"] = "/usr/bin/clang"
        ENV["CMAKE_CXX_COMPILER"] = "/usr/bin/clang++"
      
        args = %W[
          -DCMAKE_INSTALL_PREFIX=#{prefix}
          -DCMAKE_OSX_DEPLOYMENT_TARGET=#{MacOS.version}
          -DwxWidgets_CONFIG_EXECUTABLE=#{kicad_path}/wx-bin/bin/wx-config
          -DPYTHON_EXECUTABLE=/usr/bin/python
          -DPYTHON_LIBRARY=/usr/lib/libpython.dylib
          -DPYTHON_SITE_PACKAGE_PATH=#{kicad_path}/wx-bin/lib/python2.7/site-packages
          -DKICAD_SCRIPTING=ON
          -DKICAD_SCRIPTING_MODULES=ON
          -DKICAD_SCRIPTING_WXPYTHON=ON
          -DCMAKE_BUILD_TYPE=Release
          -DKICAD_SKIP_BOOST=ON
      ]

        system "cmake", "../", *args
        system "make -j4"
        system "make install"
      end
    end
end
