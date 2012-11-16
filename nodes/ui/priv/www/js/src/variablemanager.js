define([
    'lib/backbone-require',
    'src/geometrygraphsingleton', 
    ], function(Backbone, geometryGraph) {

    var Model = Backbone.Model.extend({

        initialize: function(vertex) {
            this.views = [
                new TitleView({model: this}),
                new NewVarView({model: this}),
            ];
        },

    });

    var TitleView = Backbone.View.extend({

        id: 'variable-manager',
        tagName: 'tr',

        initialize: function() {
            this.render();
            $('#variables').append(this.$el);
        },

        render: function() {
            var template = 
                '<td colspan="2" class="title">' +
                '<div class="name">Variables</div>' + 
                '</td>'; 
            var view = {};
            this.$el.html($.mustache(template, view));
            return this;
        },

        // events: {
        //     'click .add' : 'addVariable',
        // },

        // addVariable: function() {
        //     geometryGraph.addVariable('', '');
        // },

    });

    var NewVarView = Backbone.View.extend({

        tagName: 'tr',
        className: 'new-variable',

        initialize: function() {
            this.render();
            $('#variables').append(this.$el);
        },

        render: function() {
            var template = 
                '<td class="name">' +  
                '<input class="field var" placeholder="var" type="text" value="{{name}}"></input>' +
                '</td>' +
                '<td class="expression">' +  
                '<input class="field expr" placeholder="expr" type="text" value="{{expression}}"></input>' +
                '</td>';
            var view = {};
            this.$el.html($.mustache(template, view));
            return this;
        },

        events: {
            'focusout .expr' : 'addVariable',
        },

        addVariable: function() {
            var name = this.$el.find('.var').val();
            var expr = this.$el.find('.expr').val();
            if (geometryGraph.addVariable(name, expr)) {
                this.$el.find('.var').val('');
                this.$el.find('.expr').val('');
                this.$el.removeClass('error');
            } else {
                this.$el.addClass('error');
            }

        },


    });

    return new Model();


});