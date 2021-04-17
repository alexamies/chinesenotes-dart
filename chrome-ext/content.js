console.log('CNotes content script enter');

function cnLookup(term) {
  alert(`cnLookup enter ${term}`);
}

chrome.runtime.onMessage.addListener((message) => {
  console.log(`CNotes content script message recieved: ${message.term}`);
  cnLookup(message.term);
});
