chrome.runtime.onInstalled.addListener(() => {
  console.log('running background script');
  chrome.contextMenus.create({
    "id": "cnotes",
    "title": "Chinese Notes ...",
    "contexts": ["selection"]
  });
});

chrome.contextMenus.onClicked.addListener((info) => {
  console.log(`CNotes context menu clicked ${info.selectionText}`);
  chrome.tabs.query({active: true, currentWindow: true}, (tabs) => {
    chrome.tabs.sendMessage(tabs[0].id, {term: info.selectionText});
  });
});
