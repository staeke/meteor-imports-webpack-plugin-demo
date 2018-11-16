import '../both/both';
import { Meteor } from 'meteor/meteor';
import React from 'react';
import { render } from 'react-dom';
import HelloWorld from './HelloWorld.jsx';

Meteor.startup(() => {
    render(<HelloWorld />, document.getElementById('app'));
    Meteor.call('hello', (err, res) => {
        console.log(`The server replied: "${res}"`);
    })
});