
function createOrderByControl() {
    var menu = new Ext.menu.Menu();
    menu.add('<span class="menu-title">' + SqueezeJS.string('sort_by') + '...</span>');

    var selectedValue = SqueezeJS.getCookie('Squeezebox-orderBy');
    if (!selectedValue) selectedValue = 'artistalbum';
    var selectedLabel;
    for (order in orderByList) {
        var isSelected = (orderByList[order] == selectedValue);
        if (isSelected) {
            selectedLabel = order;
        }

        menu.add(new Ext.menu.CheckItem({
            text: order,
            handler: function(ev) {
                this.chooseAlbumOrderBy(orderByList[ev.text]);
            },
            scope: this,
            checked: isSelected,
            group: 'sortOrder'}));
    }

    new SqueezeJS.UI.SplitButton({
        renderTo: 'viewSelect',
        cls: 'x-btn-text',
        text: selectedLabel,
        menu: menu,
        arrowTooltip: SqueezeJS.string('display_options')
    });
}

function chooseAlbumOrderBy(option) {

    var params = location.search;
    params = params.replace(/&orderBy=[\w\.,]*/ig, '');

    if (option)
        params += '&orderBy=' + option;

    SqueezeJS.setCookie('Squeezebox-orderBy', option);
    location.search = params;
}
