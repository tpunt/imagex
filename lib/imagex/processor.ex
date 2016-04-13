defmodule Imagex.Processor do
  alias Imagex.Processor

  defstruct [:chunks, :slice_mode, :image_width, :image_height, :cutoff]

  def run(%Processor{chunks: chunks} = processor, module, func) when chunks > 0 do
    {processor, horizontal_slices, vertical_slices} = process(processor)
    process_slices(processor, horizontal_slices, vertical_slices, module, func)
  end

  defp process(%Processor{chunks: chunks, slice_mode: {:horizontal}} = processor) do
    {processor, chunks, 1}
  end

  defp process(%Processor{chunks: chunks, slice_mode: {:vertical}} = processor) do
    {processor, 1, chunks}
  end

  defp process(%Processor{chunks: chunks, slice_mode: {:grid, _orientation}} = processor) do
    if rem(chunks, 2) != 0, do: raise "Must be a multiple of 2"

    vertical_slices = :math.sqrt(chunks)
    <<_sign::size(1), _exp::size(11), mantissa::size(52)>> = <<vertical_slices::float>>

    horizontal_slices =
      if mantissa != 0 do
        vertical_slices = :math.sqrt(chunks / 2)
        <<_sign::size(1), _exp::size(11), mantissa::size(52)>> = <<vertical_slices::float>>

        if mantissa != 0, do: raise "Must be a power of 2"

        vertical_slices = round(vertical_slices)
        vertical_slices * 2
      else
        vertical_slices = round(vertical_slices)
      end

    grid_slicing(processor, horizontal_slices, vertical_slices)
  end

  defp grid_slicing(%Processor{slice_mode: {:grid, :horizontal}} = processor, horizontal_slices, vertical_slices) do
    {processor, horizontal_slices, vertical_slices}
  end

  defp grid_slicing(%Processor{slice_mode: {:grid, :vertical}} = processor, horizontal_slices, vertical_slices) do
    {processor, vertical_slices, horizontal_slices} # argument swap
  end

  defp process_slices(%Processor{image_width: width, image_height: height} = processor, horizontal_slices, vertical_slices, mod, func) do
    x_pixel_count = if vertical_slices == 1, do: width, else: round(width / vertical_slices)
    y_pixel_count = if horizontal_slices == 1, do: height, else: round(height / horizontal_slices)

    (for x <- 0..vertical_slices - 1, y <- 0..horizontal_slices - 1, do: {x, y})
    |> Enum.map(fn {x, y} ->
        spawn(mod, func, [self, x * x_pixel_count, (x + 1) * x_pixel_count, y * y_pixel_count, (y + 1) * y_pixel_count, processor])
      end)
    |> schedule_processes
  end

  defp schedule_processes(processes), do: schedule(Enum.count(processes), [])
  defp schedule(0, results), do: results
  defp schedule(process_count, results) do
    receive do
      {:ans, ans} -> schedule(process_count - 1, [ans | results])
    end
  end
end
