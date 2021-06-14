#!/usr/bin/node
const http = require('http');
const https = require('https')
const readline = require('readline');
const fs = require('fs');
const request = require('request');
const decodehtml = require('decode-html');

f = (process.argv[2]);
urlfilename = (process.argv[3]);

//checking if flag is provided 
if(f=='-urldc'||f=='-urlec'||f=='-htmldc'||f=='-curl'){
readfile(urlfilename)
}else{
console.log('-urldc		decode url');
console.log('-urlec		encode url');
console.log('-htmldc		decode html');
console.log('-curl		curl url');
}

//reading input from file or pipe
function readfile(urlfilename){
if(!urlfilename){
const file = readline.createInterface({
input: process.stdin,
output: process.stdout,
terminal: false
});
file.on('line', (line) => {
if(f=='-urldc'){
urldecode(line);
}else if(f=='-urlec'){
urlencode(line);
}else if (f=='-htmldc'){
htmldecode(line);
}else if(f=='-curl'){
curl(line);
}
});
}else{
const file = readline.createInterface({
input: fs.createReadStream(urlfilename),
output: process.stdout,
terminal: false
});
file.on('line', (line) => {
if(f=='-urldc'){
urldecode(line);
}else if(f=='-urlec'){
urlencode(line);
}else if(f=='-htmldc'){
htmldecode(line);
}else if(f=='-curl'){
curl(line);
}
});
}
}

//urldecode function
function urldecode(domains){
const uri = domains;
try {
urldc = decodeURIComponent(domains);
console.log(urldc);
}
catch (e) {
console.log(domains);
}
}

//urlencode function
function urlencode(domains){
const uri = domains;
try {
urldc = encodeURIComponent(domains);
console.log(urldc);
}
catch (e) {
console.log(domains);
}
}

//htmldecode function
function htmldecode(htmlcode){
htmldc = decodehtml(htmlcode);
console.log(htmldc);
}

//curl function
function curl(domains){
options = {
url: domains,
headers: {
'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.125 Safari/537.36',
}
};
request(options , function (error, response, body){
//request( domains , function (error, response, body) {
try{
htmldecode(body);  
}catch(e){}
//console.log(body);
//console.log(domains+'\r\n'+body || domains+'\r\n'+error);
});
}
