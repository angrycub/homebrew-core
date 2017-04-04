class Otp < Formula
  desc "Basho-specific fork of Erlang. Used to build Riak."
  homepage "http://www.basho.com"
  url "https://github.com/basho/otp/archive/OTP_R16B02_basho10.tar.gz"
  sha256 "bdcfb7ba02336de1f6fba0e6767cdde4321db4be2bb4fde7a568bab1042cfd5a"

  # Fixes problem with ODBC on Mavericks. Fixed upstream/HEAD:
  # https://github.com/erlang/otp/pull/142
  patch :DATA if MacOS.version >= :mavericks

  option "without-docs", "Do not install documentation"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "openssl"
  depends_on "unixodbc" if MacOS.version >= :mavericks
  depends_on "fop" => :optional # enables building PDF docs
  depends_on "wxmac" => :recommended # for GUI apps like observer

  resource "man" do
    url "http://erlang.org/download/otp_doc_man_R16B02.tar.gz"
    sha256 "b79ceb0383415088b5f040f2f3705632b425cb3f29c3955ef2219556abec5789"
  end

  resource "html" do
    url "http://erlang.org/download/otp_doc_html_R16B02.tar.gz"
    sha256 "2d54119b30c4d905b6b1298865309c3392fefb1580ad69725e997644bed04b7f"
  end

  def install
    ohai "Compilation takes a long time; use `brew install -v erlang` to see progress" unless ARGV.verbose?

    # Unset these so that building wx, kernel, compiler and
    # other modules doesn't fail with an unintelligable error.
    %w[LIBS FLAGS AFLAGS ZFLAGS].each { |k| ENV.delete("ERL_#{k}") }

    ENV["FOP"] = "#{HOMEBREW_PREFIX}/bin/fop" if build.with? "fop"

    # Do this if building from a checkout to generate configure
    system "./otp_build", "autoconf" if File.exist? "otp_build"

    args = %W[
      --disable-debug
      --disable-dynamic-ssl-lib
      --disable-silent-rules
      --enable-kernel-poll
      --disable-shared-zlib
      --enable-smp-support
      --enable-vm-probes 
      --enable-threads
      --disable-hipe
      --enable-darwin-64bit
      --without-wx
      --without-debugger
      --without-observer
      --without-odbc
      --with-ssl=#{Formula["openssl"].opt_prefix}
      --prefix=#{prefix}
    ]

    # args << "--enable-wx" if build.with? "wxmac"

    if MacOS.version >= :snow_leopard && MacOS::CLT.installed?
      args << "--with-dynamic-trace=dtrace"
    end

    system "./configure", *args
    system "make"
    ENV.deparallelize # Install is not thread-safe; can try to create folder twice and fail
    system "make", "install"

    if build.with? "docs"
      (lib/"erlang").install resource("man").files("man")
      doc.install resource("html")
    end
  end

  def caveats; <<-EOS.undent
    Man pages can be found in:
      #{opt_lib}/erlang/man

    Access them with `erl -man`, or add this directory to MANPATH.
    EOS
  end

  test do
    system "#{bin}/erl", "-noshell", "-eval", "crypto:start().", "-s", "init", "stop"
  end
end

__END__
diff --git a/lib/odbc/configure.in b/lib/odbc/configure.in
index 83f7a47..fd711fe 100644
--- a/lib/odbc/configure.in
+++ b/lib/odbc/configure.in
@@ -130,7 +130,7 @@ AC_SUBST(THR_LIBS)
 odbc_lib_link_success=no
 AC_SUBST(TARGET_FLAGS)
     case $host_os in
-        darwin*)
+        darwin1[[0-2]].*|darwin[[0-9]].*)
                 TARGET_FLAGS="-DUNIX"
                if test ! -d "$with_odbc" || test "$with_odbc" = "yes"; then
                    ODBC_LIB= -L"/usr/lib"
