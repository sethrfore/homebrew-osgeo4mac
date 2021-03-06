class Gdal2Grass7 < Formula
  desc "GDAL/OGR 2.x plugin for GRASS 7"
  homepage "https://www.gdal.org"
  url "https://download.osgeo.org/gdal/2.4.0/gdal-grass-2.4.0.tar.gz"
  sha256 "7f5c7f03504449524da5e6bb0042a4b4338d5e77e8bf70e694f59744801d695e"

  revision 1

  bottle do
    root_url "https://dl.bintray.com/homebrew-osgeo/osgeo-bottles"
    cellar :any
    rebuild 1
    sha256 "33340b8ecb171839029f6462d444b2bf0a4a4db01fc8018cbfdeadc6c6d1eebf" => :mojave
    sha256 "33340b8ecb171839029f6462d444b2bf0a4a4db01fc8018cbfdeadc6c6d1eebf" => :high_sierra
    sha256 "33340b8ecb171839029f6462d444b2bf0a4a4db01fc8018cbfdeadc6c6d1eebf" => :sierra
  end

  depends_on "gdal2"
  depends_on "grass7"

  def gdal_majmin_ver
    gdal_ver_list = Formula["gdal2"].version.to_s.split(".")
    "#{gdal_ver_list[0]}.#{gdal_ver_list[1]}"
  end

  def gdal_plugins_subdirectory
    "gdalplugins/#{gdal_majmin_ver}"
  end

  def install
    ENV.cxx11
    gdal = Formula["gdal2"]
    gdal_plugins = lib/gdal_plugins_subdirectory
    gdal_plugins.mkpath

    grass = Formula["grass7"]

    # due to DYLD_LIBRARY_PATH no longer being setable, strictly define extension
    inreplace "Makefile.in", ".so", ".dylib"

    system "./configure", "--prefix=#{prefix}",
                          "--disable-debug",
                          "--disable-dependency-tracking",
                          "--with-gdal=#{gdal.opt_bin}/gdal-config",
                          "--with-grass=#{grass.prefix}/grass-#{grass.version}",
                          "--with-autoload=#{gdal_plugins}"

    # inreplace "Makefile", "mkdir", "mkdir -p"

    system "make", "install"
  end

  def caveats; <<~EOS
      This formula provides a plugin that allows GDAL or OGR to access geospatial
      data stored in its format. In order to use the shared plugin, you may need
      to set the following enviroment variable:

        export GDAL_DRIVER_PATH=#{HOMEBREW_PREFIX}/lib/gdalplugins
    EOS
  end

  test do
    ENV["GDAL_DRIVER_PATH"] = "#{HOMEBREW_PREFIX}/lib/gdalplugins"
    gdal_opt_bin = Formula["gdal2"].opt_bin
    out = shell_output("#{gdal_opt_bin}/gdalinfo --formats")
    assert_match "GRASS -raster- (ro)", out
    out = shell_output("#{gdal_opt_bin}/ogrinfo --formats")
    assert_match "OGR_GRASS -vector- (ro)", out
  end
end
