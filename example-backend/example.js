var express = require('express');

var app = express();

// An array of quotes; source: http://www.journaldev.com/240/my-25-favorite-programming-quotes-that-are-funny-too
var quotes = [
    "The best thing about a boolean is even if you are wrong, you are only off by a bit. (Anonymous)",
    "Without requirements or design, programming is the art of adding bugs to an empty text file. (Louis Srygley)",
    "Before software can be reusable it first has to be usable. (Ralph Johnson)",
    "There are two ways to write error-free programs; only the third one works. (Alan J. Perlis)",
    "One [person's] crappy software is another [person's] full time job. (Jessica Gaston)",
    "A good programmer is someone who always looks both ways before crossing a one-way street. (Doug Linder)",
    "Always code as if the [person] who ends up maintaining your code will be a violent psychopath who knows where you live. (Martin Golding)",
    "Deleted code is debugged code. (Jeff Sickel)",
    "Walking on water and developing software from a specification are easy if both are frozen. (Edward V Berard)",
    "If debugging is the process of removing software bugs, then programming must be the process of putting them in. (Edsger Dijkstra)",
    "In order to understand recursion, one must first understand recursion. (Anonymous)",
    "The cheapest, fastest, and most reliable components are those that aren’t there. (Gordon Bell)",
    "The best performance improvement is the transition from the nonworking state to the working state. (J. Osterhout)"
];

// Return a random quote for all requests to the web root
app.get('*', function (req, res) {
    res.setHeader('Content-Type', 'text/html');
    var quote = quotes[Math.floor(Math.random()*quotes.length)];
    res.send(quote);
});

app.listen(4000, function () {
    console.log('Running Example app on port 4000');
});
