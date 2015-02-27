
/** TO BE UPDATED WITH MORE LANES:
 * Items Object
 */
var Kanban = {
  lanes: ["BACKLOG", "DOING", "DONE"],
  backlogItems: [["B8","B9"], ["D8","D9"],["B11","B12"],["D11","D12"],["B14","B15"],["D14","D15"],["B17","B18"],["D17","D19"]],
  doingItems: [["H8","H9"], ["J8","J9"],["H11","H12"],["J11","J12"],["H14","H15"],["J14","J15"],["H17","H18"],["J17","J19"]],
  doneItems: [["N8","N9"], ["P8","P9"],["N11","N12"],["P11","P12"],["N14","N15"],["P14","P15"],["N17","N18"],["P17","P19"]],
  /**
   * Get the first free item of a lane
   *
   * @param {string} lane name of the lane
   * @return {integer} the first free item or -1 if no more items are available
   */
  getFreeItem: function(lane) {
    switch(lane) {
      case "BACKLOG":
        for(var i =0; i < 8; i++) {
          if(ss.getRange(Kanban.backlogItems[i][0]).getValue() == "" && ss.getRange(Kanban.backlogItems[i][1]).getValue() == "") {
            return "BACKLOG:" + i;
          }
        }
        return -1;
        break;
      case "DOING":
        for(var i =0; i < 8; i++) {
          if(ss.getRange(Kanban.doingItems[i][0]).getValue() == "" && ss.getRange(Kanban.doingItems[i][1]).getValue() == "") {
            return "DOING:" + i;
          }
        }
        return -1;
        break;
      case "DONE":
        for(var i =0; i < 8; i++) {
          if(ss.getRange(Kanban.doneItems[i][0]).getValue() == "" && ss.getRange(Kanban.doneItems[i][1]).getValue() == "") {
            return "DONE:" + i;
          }
        }
        return -1;
        break;
    }
  },
  
  /**
   * Get the lane in which the cell is located
   * 
   * @param {string} cell A1 notation of the cell
   * @return {string} name of the lane or false if the cell is outside lanes or not an item cell
   */
  getLaneByCell: function(cell) {
    for(var i = 0; i < Kanban.backlogItems.length; i++) {
      if(Kanban.backlogItems[i][0] == cell || Kanban.backlogItems[i][1] == cell) {
        return "BACKLOG";
      }
    }
    for(var i = 0; i < Kanban.doingItems.length; i++) {
      if(Kanban.doingItems[i][0] == cell || Kanban.doingItems[i][1] == cell) {
        return "DOING";
      }
    }
    for(var i = 0; i < Kanban.doneItems.length; i++) {
      if(Kanban.doneItems[i][0] == cell || Kanban.doneItems[i][1] == cell) {
        return "DONE";
      }
    }
    return false;
  },
  
  /**
   * Get item by the specified cell
   *
   * @param {string} cell A1 notation of the cell
   * @return {string} name of the item or false if the cell is outside lanes or not an item cell  
   */
  getItemByCell: function(cell) {
    for(var i = 0; i < Kanban.backlogItems.length; i++) {
      if(Kanban.backlogItems[i][0] == cell || Kanban.backlogItems[i][1] == cell) {
        return "BACKLOG:" + i;
      }
    }
    for(var i = 0; i < Kanban.doingItems.length; i++) {
      if(Kanban.doingItems[i][0] == cell || Kanban.doingItems[i][1] == cell) {
        return "DOING:" + i;
      }
    }
    for(var i = 0; i < Kanban.doneItems.length; i++) {
      if(Kanban.doneItems[i][0] == cell || Kanban.doneItems[i][1] == cell) {
        return "DONE:" + i;
      }
    }
    return false;
  },
  
  /**
   * Move an item from a source to a destination position
   *
   * @param {string} source source item
   * @param {string} destination destination item
   * @return {boolean} execution result
   */
  moveItem: function(source, destination) {
    // Handle source
    var sourceSplit = source.split(':');
    var sourceLane = sourceSplit[0];
    var sourceItem = sourceSplit[1];
    
    // Handle destination
    var destinationSplit = destination.split(':');
    var destinationLane = destinationSplit[0];
    var destinationItem = destinationSplit[1];
    
    // Get the destination range
    switch(destinationLane) {
      case "BACKLOG":
        var destinationRange = ss.getRange(Kanban.backlogItems[destinationItem][0] + ":" + Kanban.backlogItems[destinationItem][1]);
        break;
      case "DOING":
        var destinationRange = ss.getRange(Kanban.doingItems[destinationItem][0] + ":" + Kanban.doingItems[destinationItem][1]);
        break;
      case "DONE":
        var destinationRange = ss.getRange(Kanban.doneItems[destinationItem][0] + ":" + Kanban.doneItems[destinationItem][1]);
        break;
    }    
    
    // Execute the copy operation
    switch(sourceLane) {
      case "BACKLOG":
        var sourceRange = ss.getRange(Kanban.backlogItems[sourceItem][0] + ":" + Kanban.backlogItems[sourceItem][1]);
        Logger.log(sourceRange.getValues());
        sourceRange.moveTo(destinationRange);
        break;
      case "DOING":
        var sourceRange = ss.getRange(Kanban.doingItems[sourceItem][0] + ":" + Kanban.doingItems[sourceItem][1]);
        sourceRange.moveTo(destinationRange);        
        break;
      case "DONE":
        var sourceRange = ss.getRange(Kanban.doneItems[sourceItem][0] + ":" + Kanban.doneItems[sourceItem][1]);
        sourceRange.moveTo(destinationRange);
        break;
    }
    
    // If the item is going to the Done lane set it to green
    if(destinationLane == "DONE") {
      destinationRange.setBackgroundColor("#89BB60");
    } else {
      destinationRange.setBackgroundColor("yellow");
    }
    
    // Clear borders for source range
    sourceRange.setBorder(false,false,false,false,false,false);
    
  },
  
  /**
   * Get the next lane
   *
   * @param {string} currentLane current lane name
   * @return {string} next lane name or false if already at the last lane
   */
  getNextLane: function(currentLane) {
    if(Kanban.lanes.indexOf(currentLane) == 2) {
      return false;
    } else {
      return Kanban.lanes[Kanban.lanes.indexOf(currentLane)+1];
    }
  },
  
  /**
   * Get the prev lane
   *
   * @param {string} currentLane current lane name
   * @return {string} prev lane name or false if already at the last lane
   */
  getPrevLane: function(currentLane) {
    if(Kanban.lanes.indexOf(currentLane) == 0) {
      return false;
    } else {
      return Kanban.lanes[Kanban.lanes.indexOf(currentLane)-1];
    }
  },
  
  /**
   * Reorder items in the specified lane
   *
   * @param {string} lane lane name to reorder
   * @return {boolean} result or the reorder operation
   */
  reorderLane: function(lane) {
    for(var i = 0; i < 8; i++) {
      if(Kanban.isEmptyItem(lane + ":" + i)) {
        Logger.log("Empty Item: " + lane + ":" + i);
        // Get next item
        var nextItem = Kanban.getNextItem(lane + ":" + i);
        Logger.log("Next Item: " + nextItem);
        if(nextItem !== false) {
          Kanban.moveItem(nextItem, lane + ":" + i);
          // Run again
          Kanban.reorderLane(lane);
        } else {
          return true;
        }
        // move the next item to this position
      }
    }
    return true;
  },
  
  /**
   * Check if the specified item is empty
   *
   * @param {string} item name of the item to check for emptyness
   * @return {boolean} true if the item is empty false otherwise
   */
  isEmptyItem: function(item) {
    var itemSplit = item.split(':');
    var itemLane = itemSplit[0];
    var itemItem = itemSplit[1];
    switch(itemLane) {
      case "BACKLOG":
        if(ss.getRange(Kanban.backlogItems[itemItem][0]).getValue() == "" && ss.getRange(Kanban.backlogItems[itemItem][1]).getValue() == "") {
            return true;
        }
        break;
      case "DOING":
        if(ss.getRange(Kanban.doingItems[itemItem][0]).getValue() == "" && ss.getRange(Kanban.doingItems[itemItem][1]).getValue() == "") {
          return true;
        }
        break;
      case "DONE":
        if(ss.getRange(Kanban.doneItems[itemItem][0]).getValue() == "" && ss.getRange(Kanban.doneItems[itemItem][1]).getValue() == "") {
          return true;
        }
        break;
    }
    return false;
  },
  
  /**
   * Get the next non empty item for the specified lane
   *
   * @param {string} item name of the item
   * @return {string} next lane item or false if no more items are present
   */
  getNextItem: function(item) {
    var itemSplit = item.split(':');
    var itemLane = itemSplit[0];
    var itemItem = itemSplit[1];
    
    // if it's the last item return false
    if(Number(itemItem) == 7) {
      return false;
    }
    
    switch(itemLane) {
      case "BACKLOG":
        for(var i = Number(itemItem) + 1; i < 8; i++) {
          if(ss.getRange(Kanban.backlogItems[i][0]).getValue() != "" || ss.getRange(Kanban.backlogItems[i][1]).getValue() != "") {
            return "BACKLOG:" + i;
          }          
        }
        break;
      case "DOING":
        for(var i = Number(itemItem) + 1; i < 8; i++) {
          if(ss.getRange(Kanban.doingItems[i][0]).getValue() != "" || ss.getRange(Kanban.doingItems[i][1]).getValue() != "") {
            return "DOING:" + i;
          }          
        }
        break;
      case "DONE":
        for(var i = Number(itemItem) + 1; i < 8; i++) {
          if(ss.getRange(Kanban.doneItems[i][0]).getValue() != "" || ss.getRange(Kanban.doneItems[i][1]).getValue() != "") {
            return "DONE:" + i;
          }          
        }
        break;
    }
    return false;   
  },
  
  /**
   * Move item up
   *
   * @param {string} cell A1 notation of the cell   
   */
  moveItemUp: function(cell) {
    var item = Kanban.getItemByCell(cell);
    var itemSplit = item.split(':');
    var itemLane = itemSplit[0];
    var itemItem = itemSplit[1];
    
    // If it's the first item we can't move it up
    if(Number(itemItem) == 0) {
      return false;
    }
    
    var prevItem = Number(itemItem) - 1;
    Kanban.exchangeItems(item, itemLane + ":" + prevItem);
    
  },
  
  /**
   * Move item down
   *
   * @param {string} cell A1 notation of the cell   
   */
  moveItemDown: function(cell) {
    var item = Kanban.getItemByCell(cell);
    var itemSplit = item.split(':');
    var itemLane = itemSplit[0];
    var itemItem = itemSplit[1];
    
    // If it's the last item we can't move it down
    if(Number(itemItem) == 7) {
      return false;
    }
    
    var nextItem = Number(itemItem) + 1;
    Kanban.exchangeItems(item, itemLane + ":" + nextItem);
    
  },  
  
  /**
   * Exchange items
   *
   * @param {string} itemA name of the item
   * @param {string} itemB name of the item   
   */
  exchangeItems: function(itemA, itemB) {
    // Exchange only filled items
    if(Kanban.isEmptyItem(itemA) === false && Kanban.isEmptyItem(itemB) === false) {
      var itemAValues = Kanban.getItemValues(itemA);
      var itemBValues = Kanban.getItemValues(itemB);
      Kanban.setItemValues(itemA, itemBValues);
      Kanban.setItemValues(itemB, itemAValues);   
    }
  },
  
  /**
   * Get values for an item
   *
   * @param {string} item name of the item
   * @return {array} values for the item
   */
  getItemValues: function(item) {
    var itemSplit = item.split(':');
    var itemLane = itemSplit[0];
    var itemItem = Number(itemSplit[1]);
    
    switch(itemLane) {
      case "BACKLOG":
        return ss.getRange(Kanban.backlogItems[itemItem][0] + ":" + Kanban.backlogItems[itemItem][1]).getValues();         
        break;
      case "DOING":
        return ss.getRange(Kanban.doingItems[itemItem][0] + ":" + Kanban.doingItems[itemItem][1]).getValues();   
        break;
      case "DONE":
        return ss.getRange(Kanban.doneItems[itemItem][0] + ":" + Kanban.doneItems[itemItem][1]).getValues();   
        break;
    }    
  },
  
  /**
   * Set values for an item
   *
   * @param {string} item name of the item
   * @param {array} values values to set for the item  
   * @return {boolean} result
   */
  setItemValues: function(item, values) {
    var itemSplit = item.split(':');
    var itemLane = itemSplit[0];
    var itemItem = Number(itemSplit[1]);
    
    switch(itemLane) {
      case "BACKLOG":
        return ss.getRange(Kanban.backlogItems[itemItem][0] + ":" + Kanban.backlogItems[itemItem][1]).setValues(values);         
        break;
      case "DOING":
        return ss.getRange(Kanban.doingItems[itemItem][0] + ":" + Kanban.doingItems[itemItem][1]).setValues(values);   
        break;
      case "DONE":
        return ss.getRange(Kanban.doneItems[itemItem][0] + ":" + Kanban.doneItems[itemItem][1]).setValues(values);   
        break;
    }    
  },
  
  /**
   * Delete an item
   *
   * @param {string} cell A1 notation of the cell
   * @return {bool} result
   */
  deleteItem: function(cell) {
    var item = Kanban.getItemByCell(cell);
    var itemSplit = item.split(':');
    var itemLane = itemSplit[0];
    var itemItem = Number(itemSplit[1]);
    
    switch(itemLane) {
      case "BACKLOG":
        return ss.getRange(Kanban.backlogItems[itemItem][0] + ":" + Kanban.backlogItems[itemItem][1]).clear().setBorder(false,false,false,false,false,false);        
        break;
      case "DOING":
        return ss.getRange(Kanban.doingItems[itemItem][0] + ":" + Kanban.doingItems[itemItem][1]).clear().setBorder(false,false,false,false,false,false);    
        break;
      case "DONE":
        return ss.getRange(Kanban.doneItems[itemItem][0] + ":" + Kanban.doneItems[itemItem][1]).clear().setBorder(false,false,false,false,false,false);    
        break;
    }     
  },
  
  /**
   * Check if the specified lane is the first one
   *
   * @param {string} lane lane name
   * @return {boolean} true if the specified lane is the first one, false otherwise
   */
  isFirstLane: function(lane) {
    if(Kanban.lanes.indexOf(lane) == 0) {
      return true;
    } else {
      return false;
    }
  },
  
  /**
   * Check if the specified lane is the last one
   *
   * @param {string} lane lane name
   * @return {boolean} true if the specified lane is the last one, false otherwise
   */
  isLastLane: function(lane) {
    if(Kanban.lanes.indexOf(lane) == 2) {
      return true;
    } else {
      return false;
    }
  },
  
  /**
   * Set impediment on the specified item
   *
   * @param {string} item name of the item
   */
  setImpediment: function(item) {
    var itemSplit = item.split(':');
    var itemLane = itemSplit[0];
    var itemItem = Number(itemSplit[1]);
    
    switch(itemLane) {
      case "BACKLOG":
        return ss.getRange(Kanban.backlogItems[itemItem][0] + ":" + Kanban.backlogItems[itemItem][1]).setBackgroundColor("red");         
        break;
      case "DOING":
        return ss.getRange(Kanban.doingItems[itemItem][0] + ":" + Kanban.doingItems[itemItem][1]).setBackgroundColor("red");     
        break;
      case "DONE":
        return ss.getRange(Kanban.doneItems[itemItem][0] + ":" + Kanban.doneItems[itemItem][1]).setBackgroundColor("red");     
        break;
    }    
  },
  
  /**
   * Remove impediment from the specified item
   *
   * @param {string} item name of the item
   */
  removeImpediment: function(item) {
    var itemSplit = item.split(':');
    var itemLane = itemSplit[0];
    var itemItem = Number(itemSplit[1]);
    
    switch(itemLane) {
      case "BACKLOG":
        return ss.getRange(Kanban.backlogItems[itemItem][0] + ":" + Kanban.backlogItems[itemItem][1]).setBackgroundColor("yellow");         
        break;
      case "DOING":
        return ss.getRange(Kanban.doingItems[itemItem][0] + ":" + Kanban.doingItems[itemItem][1]).setBackgroundColor("yellow");     
        break;
      case "DONE":
        return ss.getRange(Kanban.doneItems[itemItem][0] + ":" + Kanban.doneItems[itemItem][1]).setBackgroundColor("yellow");     
        break;
    }    
  },
  
  /**
   * Clear all Kanban items
   */
  clear: function() {
    
    // Clear the BACKLOG lane
    for(var i =0; i < 8; i++) {
      ss.getRange(Kanban.backlogItems[i][0] + ":" + Kanban.backlogItems[i][1]).clear().setBorder(false,false,false,false,false,false);
    } 
    
    // Clear the DOING lane
    for(var i =0; i < 8; i++) {
      ss.getRange(Kanban.doingItems[i][0] + ":" + Kanban.doingItems[i][1]).clear().setBorder(false,false,false,false,false,false);
    } 
    
    // Clear the DONE lane
    for(var i =0; i < 8; i++) {
      ss.getRange(Kanban.doneItems[i][0] + ":" + Kanban.doneItems[i][1]).clear().setBorder(false,false,false,false,false,false);
    }     
  },
  
  /**
   * Create a new item
   *
   * @param {integer} item position of the item in the lane
   * @param {string} title title of the item
   * @param {string} description description of the item
   * @return {boolean} result
   */
  createItem: function(item, title, description) {
    var itemSplit = item.split(':');
    var itemLane = itemSplit[0];
    var itemItem = Number(itemSplit[1]);
    switch(itemLane) {
      case "BACKLOG":
        ss.getRange(Kanban.backlogItems[itemItem][0]).setValue(title).setFontWeight("bold").setBackgroundColor("yellow").setBorder(true,true,true,true,false,false);
        ss.getRange(Kanban.backlogItems[itemItem][1]).setValue(description).setBackgroundColor("yellow").setVerticalAlignment("top").setBorder(true,true,true,true,false,false);
        break;
      case "DOING":
        ss.getRange(Kanban.doingItems[itemItem][0]).setValue(title).setFontWeight("bold").setBackgroundColor("yellow").setBorder(true,true,true,true,false,false);
        ss.getRange(Kanban.doingItems[itemItem][1]).setValue(description).setBackgroundColor("yellow").setVerticalAlignment("top").setBorder(true,true,true,true,false,false); 
        break;
      case "DONE":
        ss.getRange(Kanban.doneItems[itemItem][0]).setValue(title).setFontWeight("bold").setBackgroundColor("yellow").setBorder(true,true,true,true,false,false);
        ss.getRange(Kanban.doneItems[itemItem][1]).setValue(description).setBackgroundColor("yellow").setVerticalAlignment("top").setBorder(true,true,true,true,false,false); 
        break;
    }     
  }
  
}


