function draw()
	value = GetTagValue(UiGetScreen(), "path")
	UiImageBox(value, UiWidth(), UiHeight())
end