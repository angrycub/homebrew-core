class Riak < Formula
  desc "Distributed database insipred by dynamo"
  homepage "http://basho.com/products/riak-kv/"
  url "http://s3.amazonaws.com/downloads.basho.com/riak/2.2/2.2.3/riak-2.2.3.tar.gz"
  sha256 "0a82a16c7fe004ac8223ad27db35f9c1c5f16c147161a04d9cdad31ac1f0b447"

  depends_on :macos => :mountain_lion
  depends_on :arch => :x86_64
  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "otp" => :build
  depends_on "openssl"

  def install
    ENV.deparallelize
    system "make", "rel"

    logdir = var + "log/riak"
    datadir = var + "lib/riak"
    libexec.install Dir["rel/riak/*"]
    logdir.mkpath
    datadir.mkpath
    (datadir + "ring").mkpath
    inreplace "#{libexec}/lib/env.sh" do |s|
      s.change_make_var! "RUNNER_BASE_DIR", libexec
      s.change_make_var! "RUNNER_LOG_DIR", logdir
    end
    inreplace "#{libexec}/etc/riak.conf" do |c|
      c.gsub! /(platform_data_dir *=).*$/, "\\1 #{datadir}"
      c.gsub! /(platform_log_dir *=).*$/, "\\1 #{logdir}"
    end
    bin.write_exec_script libexec/"bin/riak"
    bin.write_exec_script libexec/"bin/riak-admin"
    bin.write_exec_script libexec/"bin/riak-debug"
    bin.write_exec_script libexec/"bin/search-cmd"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/riak version")
  end
end
