var chai = require('chai'),
    assert = chai.assert,
    requirejs = require('requirejs');

chai.Assertion.includeStack = true;

requirejs.config({
    baseUrl: '..',
    nodeRequire: require,
});

var graphLib = requirejs('src/graph');

describe('Graph', function() {

    it('can be empty', function() {
        var graph = new graphLib.Graph();

        assert.equal(graph.size(), 0);
    });

    it('has vertices', function() {
        var graph = new graphLib.Graph();
        assert.equal(graph.size(), 0);

        var a = {id:'a'}, b = {id:'b'};
        graph.addVertex(a);
        graph.addVertex(b);

        assert.equal(graph.size(), 2);
        assert.deepEqual(graph.vertices(), [a, b]);

    });

    it('manages incoming and outgoing vertices', function() {

        var a = {id:'a'}, b = {id:'b'}, c = {id:'c'};
        var graph = new graphLib.Graph();
        assert.equal(graph.size(), 0);

        graph.addVertex(a);        
        graph.addVertex(b); 
        graph.addVertex(c); 
        graph.addEdge(a,b);
        graph.addEdge(a,c);
        graph.addEdge(b,c);

        assert.equal(graph.size(), 3);
        assert.deepEqual(graph.outgoingVerticesOf(a), ['b', 'c']);
        assert.deepEqual(graph.outgoingVerticesOf(b), ['c']);
        assert.deepEqual(graph.outgoingVerticesOf(c), []);
        assert.deepEqual(graph.incomingVerticesOf(a), []);
        assert.deepEqual(graph.incomingVerticesOf(b), ['a']);
        assert.deepEqual(graph.incomingVerticesOf(c), ['a', 'b']);

        graph.removeVertex(b);

        assert.equal(graph.size(), 2);
        assert.deepEqual(graph.outgoingVerticesOf(a), ['c']);
        assert.deepEqual(graph.outgoingVerticesOf(b), []);
        assert.deepEqual(graph.outgoingVerticesOf(c), []);  
        assert.deepEqual(graph.incomingVerticesOf(a), []);
        assert.deepEqual(graph.incomingVerticesOf(b), []);
        assert.deepEqual(graph.incomingVerticesOf(c), ['a']);

        graph.removeVertex(a);

        assert.equal(graph.size(), 1);
        assert.deepEqual(graph.outgoingVerticesOf(a), []);
        assert.deepEqual(graph.outgoingVerticesOf(b), []);
        assert.deepEqual(graph.outgoingVerticesOf(c), []);
        assert.deepEqual(graph.incomingVerticesOf(a), []);
        assert.deepEqual(graph.incomingVerticesOf(b), []);
        assert.deepEqual(graph.incomingVerticesOf(c), []);

    });

    it('can replace vertices and maintain the edges', function() {

        var a = {id:'a'}, b = {id:'b'}, c = {id:'c'};
        var graph = new graphLib.Graph();

        graph.addVertex(a);        
        graph.addVertex(b); 
        graph.addVertex(c); 
        graph.addEdge(a,b);
        graph.addEdge(a,c);
        graph.addEdge(b,c);

        assert.deepEqual(graph.outgoingVerticesOf(a), ['b', 'c']);
        assert.deepEqual(graph.outgoingVerticesOf(b), ['c']);
        assert.deepEqual(graph.outgoingVerticesOf(c), []);
        assert.deepEqual(graph.incomingVerticesOf(a), []);
        assert.deepEqual(graph.incomingVerticesOf(b), ['a']);
        assert.deepEqual(graph.incomingVerticesOf(c), ['a', 'b']);

        var d = {id:'d'};
        graph.replaceVertex(b, d);

        assert.deepEqual(graph.outgoingVerticesOf(a), ['d', 'c']);
        assert.deepEqual(graph.outgoingVerticesOf(d), ['c']);
        assert.deepEqual(graph.outgoingVerticesOf(c), []);
        assert.deepEqual(graph.incomingVerticesOf(a), []);
        assert.deepEqual(graph.incomingVerticesOf(d), ['a']);
        assert.deepEqual(graph.incomingVerticesOf(c), ['a', 'd']);

    });

    it('can replace vertices with the same id', function() {

        var a = {id:'a'}, b1 = {id:'b'}, b2 = {id: 'b'}, c = {id:'c'};
        var graph = new graphLib.Graph();

        graph.addVertex(a);        
        graph.addVertex(b1); 
        graph.addVertex(c); 
        graph.addEdge(a,b1);
        graph.addEdge(a,c);
        graph.addEdge(b1,c);

        assert.deepEqual(graph.outgoingVerticesOf(a), ['b', 'c']);
        assert.deepEqual(graph.outgoingVerticesOf(b1), ['c']);
        assert.deepEqual(graph.outgoingVerticesOf(c), []);
        assert.deepEqual(graph.incomingVerticesOf(a), []);
        assert.deepEqual(graph.incomingVerticesOf(b1), ['a']);
        assert.deepEqual(graph.incomingVerticesOf(c), ['a', 'b']);

        graph.replaceVertex(b1, b2);

        assert.deepEqual(graph.outgoingVerticesOf(a), ['b', 'c']);
        assert.deepEqual(graph.outgoingVerticesOf(b2), ['c']);
        assert.deepEqual(graph.outgoingVerticesOf(c), []);
        assert.deepEqual(graph.incomingVerticesOf(a), []);
        assert.deepEqual(graph.incomingVerticesOf(b2), ['a']);
        assert.deepEqual(graph.incomingVerticesOf(c), ['a', 'b']);

    });

});