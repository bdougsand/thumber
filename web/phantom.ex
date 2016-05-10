defmodule Thumber.Phantom do
  def start() do
    script = Path.join(System.cwd, "capture.js")

    if File.exists?(script) do
      img_dir = Path.join(System.cwd, "thumb")
      env = [{"PHANTOM_PORT", "8080"},
             {"THUMBER_IMG_DIR", img_dir},
             {"THUMBER_IMG_URL", "/thumb"}]
      System.cmd("phantomjs", [script], env: env)
    end
  end

  def create(url) do
    
  end
end
