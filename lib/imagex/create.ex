defmodule Imagex.Create do
  alias Imagex.Processor

  def create(set, %Processor{image_width: width, image_height: height, cutoff: cutoff}, filename) do
    image = :egd.create(width, height)

    for e <- set do
      {i, j, k} = e
      level = if k < cutoff, do: (k / cutoff) * 255, else: 0

      :egd.filledRectangle(image, {i, j}, {i, j}, :egd.color({level/4, level, level}))
    end

    :egd.save(:egd.render(image, :png), filename)
  end
end
