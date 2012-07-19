

# reverses jQuery selection
$.fn.reverse = [].reverse


# node radius (16 in not scaled version)
RADIUS = 8.0


# enum describing possible states when dragging 
DRAGGING =
	A: 1
	B: 2


# paints current nodes and obstacles on canvas
repaint = () ->

	$("#paper").clearCanvas()

	# perform drawing for each node
	$(".ui-node").each(() ->
		# get position (0 if empty string)
		px = Number($(this).find(".x").val()) / 2.0
		py = Number($(this).find(".y").val()) / 2.0
		
		# get stroke and set default if none
		stroke = $(this).find(".stroke").val()
		stroke = if stroke == "" then "#000000" else "#" + stroke
		
		# same with fill
		fill = $(this).find(".fill").val()
		fill = if fill == "" then undefined else "#" + fill
		
		$("#paper").drawArc(
			strokeWidth: 4.0
			strokeStyle: stroke
			fillStyle: fill
			x: px
			y: py
			radius: RADIUS
		)

		# draw a letter whether a node is a starting node or ending node
		letter = null
		letter = "S" if $(this).find('[name="starting"]').is(":checked")
		letter = "E" if $(this).find('[name="ending"]').is(":checked")
		
		if letter?
			$("#paper").drawText(
				fillStyle: "#000000",
				strokeStyle: "#ffffff",
				strokeWidth: 1.0,
				x: px,
				y: py,
				font: "10pt",
				text: letter
			)
	)

	# and perform drawing for each obstacle
	$(".ui-obstacle").each(() ->
		# get position of segment (0 if empty string)
		pax = Number($(this).find(".ax").val()) / 2.0
		pay = Number($(this).find(".ay").val()) / 2.0
		pbx = Number($(this).find(".bx").val()) / 2.0
		pby = Number($(this).find(".by").val()) / 2.0
		
		$("#paper")
			.drawLine(
				strokeStyle: "#ffffff"
				strokeWidth: 4.0
				x1: pax
				y1: pay
				x2: pbx
				y2: pby
			)
			.drawArc(
				fillStyle: "#ffffff"
				x: pax
				y: pay
				radius: 4.0
			)
			.drawArc(
				fillStyle: "#ffffff"
				x: pbx
				y: pby
				radius: RADIUS / 2.0
			)
	)


jsonify = () ->
	result = ""

	# open object
	result += "{\n"

	# process nodes
	result += "  nodes: [\n"
	$(".ui-node").each((index) ->
		result += ",\n" if index
		result += "    {\n"
		result += "      \"x\": #{Number($(this).find(".x").val())}"
		result += ",\n"
		result += "      \"y\": #{Number($(this).find(".y").val())}"
		
		stroke = $(this).find(".stroke").val()
		unless stroke is ""
			result += ",\n"
			result += "      \"stroke\": \"#{stroke}\""
		
		fill = $(this).find(".fill").val()
		unless fill is ""
			result += ",\n"
			result += "      \"fill\": \"#{fill}\""

		starting = $(this).find('[name="starting"]').is(":checked")
		if starting
			result += ",\n"
			result += "      \"starting\": true"

		ending = $(this).find('[name="ending"]').is(":checked")
		if ending
			result += ",\n"
			result += "      \"ending\": true"

		result += "\n    }"
	)
	result += "\n  ],\n"

	# process obstacles
	result += "  obstacles: [\n"
	$(".ui-obstacle").each((index) ->
		result += ",\n" if index
		result += "    {\n"
		result += "      \"ax\": #{Number($(this).find(".ax").val())},\n"
		result += "      \"ay\": #{Number($(this).find(".ay").val())},\n"
		result += "      \"bx\": #{Number($(this).find(".bx").val())},\n"
		result += "      \"by\": #{Number($(this).find(".by").val())}\n"
		result += "    }"
	)
	result += "\n  ]\n"

	# close object
	result += "}"

	return result


$(document).ready(() ->

	$("#ui-add-node").click(() ->
		$(this).parent().parent().before('
			<tr class="ui-node">
				<td><input class="x" placeholder="x" style="width: 40px" value="512" /></td>
				<td><input class="y" placeholder="y" style="width: 40px" value="512" /></td>
				<td><input class="stroke" placeholder="000000" style="width: 80px" /></td>
				<td><input class="fill" placeholder="undefined" style="width: 80px" /></td>
				<td><input name="starting" type="radio" /></td>
				<td><input name="ending" type="radio" /></td>
				<td><button class="ui-remove">X</button></td>
			</tr>
		')
		repaint()
	)

	$("#ui-add-obstacle").click(() ->
		$(this).parent().parent().before('
			<tr class="ui-obstacle">
				<td><input class="ax" placeholder="x" value="256"/></td>
				<td><input class="ay" placeholder="y" value="512"/></td>
				<td><input class="bx" placeholder="x" value="768"/></td>
				<td><input class="by" placeholder="y" value="512"/></td>
				<td><button class="ui-remove">X</button></td>
			</tr>
		')
		repaint()
	)

	$(document).on("click", ".ui-remove", () ->
		$(this).parent().parent().remove()
		repaint()
	)

	$(document).on("click keypress change", "#ui input", () ->
		repaint()
	)

	$(document).on("mousedown", '#ui input[type="radio"]', () ->
		$self = $(this)
		if $self.is(":checked")
			uncheck = () ->
				setTimeout(
					() ->
						$self.removeAttr("checked")
						repaint()
					0
				)
				$self.off("mouseup", uncheck)
			$self.on("mouseup", uncheck)
	)

	# keyboard shortcuts
	clamp = false
	$(window).keydown((event) ->
		clamp = true if event.which == 17
	)
	$(window).keyup((event) ->
		clamp = false if event.which == 17
	)

	# drag and drop mechanism for preview
	dragged = null
	prevX = prevY = 0
	$("#paper")
		.mousedown((event) ->
			cx = event.offsetX
			cy = event.offsetY

			# search for dragged object in nodes
			$(".ui-node").reverse().each(() ->
				px = $(this).find(".x").val() / 2.0
				py = $(this).find(".y").val() / 2.0
				
				x = (px - cx) * (px - cx)
				y = (py - cy) * (py - cy)
				if x + y < RADIUS * RADIUS
					dragged = $(this)
					return false
			)

			# dragged element has been found
			if dragged?
				return

			# continue searching in obstacles
			$(".ui-obstacle").reverse().each(() ->
				# A point is being dragged
				pax = $(this).find(".ax").val() / 2.0
				pay = $(this).find(".ay").val() / 2.0
				da = (pax - cx) * (pax - cx) + (pay - cy) * (pay - cy)
				if da < RADIUS * RADIUS / 4.0
					dragged = $(this)
					dragged.which = DRAGGING.A
					return false

				# B point is being dragged
				pbx = $(this).find(".bx").val() / 2.0
				pby = $(this).find(".by").val() / 2.0
				db = (pbx - cx) * (pbx - cx) + (pby - cy) * (pby - cy)
				if db < RADIUS * RADIUS / 4.0
					dragged = $(this)
					dragged.which = DRAGGING.B
					return false
			)
		)
		.mouseup((event) ->
			dragged = null
		)
		.mousemove((event) ->
			# update delta of the position
			dx = event.offsetX - prevX
			dy = event.offsetY - prevY
			prevX = event.offsetX
			prevY = event.offsetY

			# nothing do drag, nothing to do here
			unless dragged?
				return

			# check whether we are moving an node
			if dragged.hasClass("ui-node")
				$x = dragged.find(".x")
				$y = dragged.find(".y")

			# or a obstacle node case
			if dragged.hasClass("ui-obstacle")
				if dragged.which & DRAGGING.A
					$x = dragged.find(".ax")
					$y = dragged.find(".ay")
				if dragged.which & DRAGGING.B
					$x = dragged.find(".bx")
					$y = dragged.find(".by")

			newX = Number($x.val()) + dx * 2
			newY = Number($y.val()) + dy * 2
			
			# check whether we should clamp to the grid
			if clamp
				$x.val((event.offsetX - event.offsetX % 32) * 2)
				$y.val((event.offsetY - event.offsetY % 32) * 2)
			else
				$x.val(String(newX))
				$y.val(String(newY))

			repaint()
		)

	$("#jsonify").click(() ->
		window.prompt("Generated JSON", jsonify())
	)
)
