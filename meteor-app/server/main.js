import './serve_wp_bundle';
import {Meteor} from 'meteor/meteor';
import '../imports/both/both';


Meteor.startup(() => {
    // code to run on server at startup
    console.log('The server is starting');
});
