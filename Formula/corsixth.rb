class Corsixth < Formula
  desc "Open source clone of Theme Hospital"
  homepage "https://github.com/CorsixTH/CorsixTH"
  url "https://github.com/CorsixTH/CorsixTH/archive/v0.65.tar.gz"
  sha256 "4994823833d13fecc4553b7ddd1e3102abcd8501baa23f18cb5a2c315e1db2c0"
  license "MIT"
  head "https://github.com/CorsixTH/CorsixTH.git"

  bottle do
    sha256 arm64_big_sur: "9cb15180b7b5b1ce5a5cc8db33bc51e86d99d4f31f85cafc798732e936a8c43b"
    sha256 big_sur:       "4383665253bff0c2b2bd48ad55c9834f49e4718656ddadfdb70a8cb440d47196"
    sha256 catalina:      "611611a2db4ba0265ca31748dd5ba61b3b43f3bd996e42bef75bbb8ad99c5e85"
    sha256 mojave:        "c6b63dfbf4056ddf0fd48ad3538906ec0a2bfbc31ef8fe8301e04e12cf6792f3"
  end

  depends_on "cmake" => :build
  depends_on "luarocks" => :build
  depends_on xcode: :build
  depends_on "ffmpeg"
  depends_on "freetype"
  depends_on "lua"
  depends_on "sdl2"
  depends_on "sdl2_mixer"

  resource "lpeg" do
    url "http://www.inf.puc-rio.br/~roberto/lpeg/lpeg-1.0.2.tar.gz"
    mirror "https://sources.voidlinux.org/lua-lpeg-1.0.2/lpeg-1.0.2.tar.gz"
    sha256 "48d66576051b6c78388faad09b70493093264588fcd0f258ddaab1cdd4a15ffe"
  end

  resource "luafilesystem" do
    url "https://github.com/keplerproject/luafilesystem/archive/v1_8_0.tar.gz"
    sha256 "16d17c788b8093f2047325343f5e9b74cccb1ea96001e45914a58bbae8932495"
  end

  def install
    # Make sure I point to the right version!
    lua = Formula["lua"]

    ENV["TARGET_BUILD_DIR"] = "."
    ENV["FULL_PRODUCT_NAME"] = "CorsixTH.app"

    luapath = libexec/"vendor"
    ENV["LUA_PATH"] = luapath/"share/lua"/lua.version.major_minor/"?.lua"
    ENV["LUA_CPATH"] = luapath/"lib/lua"/lua.version.major_minor/"?.so"

    resources.each do |r|
      r.stage do
        system "luarocks", "build", r.name, "--tree=#{luapath}"
      end
    end

    system "cmake", ".", "-DLUA_INCLUDE_DIR=#{lua.opt_include}/lua",
                         "-DLUA_LIBRARY=#{lua.opt_lib}/liblua.dylib",
                         "-DLUA_PROGRAM_PATH=#{lua.opt_bin}/lua",
                         "-DCORSIX_TH_DATADIR=#{prefix}/CorsixTH.app/Contents/Resources/",
                         *std_cmake_args
    system "make"
    cp_r %w[CorsixTH/CorsixTH.lua CorsixTH/Lua CorsixTH/Levels CorsixTH/Campaigns CorsixTH/Graphics CorsixTH/Bitmap],
         "CorsixTH/CorsixTH.app/Contents/Resources/"
    prefix.install "CorsixTH/CorsixTH.app"

    lua_env = { LUA_PATH: ENV["LUA_PATH"], LUA_CPATH: ENV["LUA_CPATH"] }
    (bin/"CorsixTH").write_env_script(prefix/"CorsixTH.app/Contents/MacOS/CorsixTH", lua_env)
  end

  test do
    lua = Formula["lua"]

    app = prefix/"CorsixTH.app/Contents/MacOS/CorsixTH"
    assert_includes MachO::Tools.dylibs(app), "#{lua.opt_lib}/liblua.dylib"
  end
end
