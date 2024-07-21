function doGlobalDocumentsAction(target) {
    $("#actions").addClass("d-none");
    $("#loader").removeClass("d-none");

    let form = $('#__AjaxAntiForgeryForm');
    let token = $('input[name="__RequestVerificationToken"]', form).val();

    $.ajax({
        url: $(target).data('url'),
        type: 'POST',
        data: {
            __RequestVerificationToken: token,
        },        
        success: function (result) {
            $('#partialActions').html(result);
            console.log('success');
            console.log(result);
        },
        error: function (xhr, status, error) {
            console.error("Error loading documents:", error);
        }
    });
}
