--[[

							Table Utils
						 Read Before Using
	
	Version: 1;0.8
	
	Release Version: 1.0.8

	TODO: 
	TableUtils.new() --> This is the normal Table. Examples:
	`local Table=TableUtils.new()`.
	
	Table:push(Element) --> Adds a element for the new table you created:
	`Table:push('This is a value!')
	 Table:push(123)
	 Table:push(function() print 'Hello World!' end))
	`
	
	Table:pop() --> Removes and returns the first element on the table:
	`Table:push('Forward')-- element adding
	 Table:push('Backward')
	 
	 --The first item on the entry is the first to be removed
	 local NEXT=Table:pop()
	 print(NEXT) --Output: 'Forward'
	 -- Now it will print the next element on the list:
	 
	 print(Table:pop()) --Output: 'Backward'
	`
	
	Table:removeAt(IndexNumber) --> Removes a element by its index on the table. Examples: [1]='Cheese Burger'
	`Table:push('Cheese') --the first entry
	 Table:removeAt(1) --Removed: 'Cheese'
	`
	
	Table:remove(Element) --> Removes a element by its name:
	`Table:push('Hello World!')
	 Table:remove('Hello World!') --Removed: 'Hello World!'
	`
	
	Table:isEmpty() --> Verifies if the table is empty:
	`if Table:isEmpty() then
	 	print('The Table is Empty!!')
	 end
	`
	
	Table:size() --Returns the amount of existing elements in the table:
	`Table:push('Bread')
	 Table:push('Cheese')
	 Table:push('Ketchup')
	 Table:push('Meat')
	 
	 print(Table:size())-- Output: 4
	`
	
	Table:onPush()--A function that executes whats inside of it when a element is added:
	`Table:onPush(function(item,size)
	 	print(string.format('New item added: %s / Total: %d', tostring(item), currentSize))
	 end)
	`
	--INFO: This function isn't recommended for casual uses
	Table:_notify() --> A internal function that can be used for warning via :push automatically. . You still can use it by forcing firing a manual event:
	`Table:onPush(function(item,i)
		 print('Alert received for item',item)
	 end)
	 
	 Table:_notify('Banana')--Output: Alert received for item Banana
	`
	
	Table:proccess()-- Executes a function for every element on the table on a sequence:
	`Table:push('Loading 1')
	 Table:push('Connecting...')
	 Table:push('Loading 3')
	 
	 Table:proccess(function(item,index)
	 	print(string.format('[Index %d] Executing: %s',index,item))
	    if item == 'Connecting...'' then
	        return true 
	    end
	    return true
	 end)
	`
]]
local TableUtils={};
TableUtils.__index = TableUtils
function TableUtils.new()
	local self=setmetatable({}, TableUtils);
	self._list={};
	self._first=1;
	self._last=0;
	self._listeners={};
	self._isProcessing=false;
	return self;
end;
function TableUtils:push(value)
	self._last = self._last + 1;
	self._list[self._last]=value;
	self:_notify(value);
end;
function TableUtils:pop()
	if self:isEmpty() then
		return nil;
	end
	local value=self._list[self._first];
	self._list[self._first]=nil;
	self._first=self._first+1;
	return value;
end;
function TableUtils:removeAt(position)
	local internalIndex=self._first+position-1;
	if internalIndex<self._first or internalIndex>self._last then
		return nil;
	end;
	local removedValue=self._list[internalIndex];
	for i=internalIndex,self._last-1 do
		self._list[i]=self._list[i+1];
	end
	self._list[self._last]=nil;
	self._last = self._last-1;
	return removedValue;
end
function TableUtils:remove(targetValue)
	for i=self._first,self._last do
		if self._list[i]==targetValue then
			local relativePosition=(i-self._first)+1;
			return self:removeAt(relativePosition);
		end;
	end;
	return nil;
end;
function TableUtils:isEmpty()
	return self._first>self._last;
end;
function TableUtils:size()
	return (self._last-self._first)+1;
end;
function TableUtils:onPush(callback)
	if type(callback) == "function" then
		table.insert(self._listeners,callback);
	end;
end;
function TableUtils:_notify(item)
	for _, listener in ipairs(self._listeners) do
		pcall(listener, item,self:size());
	end;
end;
function TableUtils:process(handlerFunc)
	if self._isProcessing then return end
	self._isProcessing=true;
	while self._isProcessing and not self:isEmpty() do
		local currentIndex=self._first;
		local currentItem=self:pop();
		local success,result=pcall(handlerFunc,currentItem,currentIndex);
		if not success or result~=true then
			self._isProcessing=false;
			break;
		end;
	end;
	self._isProcessing=false;
end
return TableUtils;
