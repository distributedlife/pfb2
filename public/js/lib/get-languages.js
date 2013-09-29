$.get("/languages", function(data) {
	data.supported_languages.forEach(function(language) {
		$("#languages").append("<div class='language'><a href='/" + language + "/review'>" + language + "</a></div>");
	});
});