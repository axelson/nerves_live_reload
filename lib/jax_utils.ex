defmodule JaxUtils do
  use Boundary, deps: [], exports: []

  defdelegate play_sound(sound_name), to: JaxUtils.SoundPlayer, as: :play
end
