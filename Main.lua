--[[

							Table Utils
						 Read Before Using
	
	Version: 1.2.0
	
	Release Version: 1.2.0

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
	
	Table:stopProcess() --> Stops a currently running :proccess function for a table. Examples:
	`Table:push('Apple A')
	 Table:push('Apple B')
	 Table:push('Apple C')
	 
	 Table:proccess(function(item,index)
	 	if item=='Apple C' then
	 	 print('Counting reached its condition, stopping...')
	 	 -- OR --
	 	 Table:stopProccess()
	 	 --return false <-Only if you don't want to use stopProccess
	 	end
	 	return true
	 end)
	`
	
	--INFO: This function isn't recommended for casual uses
	Table:_run() --> A internal functon that can be used for :proccess method.
	
	Table:clear() --> Destroy every existing element on the table. This function also can return true or false when realizing the action.
	`Table:push('Banana')
	 Table:push('Banana 2')
	 Table:push('Apple ')
	 Table:push('Apple')
	 Table:push('Apple 1')
	 
	 Table:clear() --> everything will be destroyed
	 -- OR --
	 if Table:clear() then
	 	print('Successfully cleared Table!')
	 else
	 	print('Something went wrong!')
	 end
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
	self._handler=nil;
	self._destroyed=false;
	return self;
end;
function TableUtils:push(value)
	if self:isDestroyed() then
		warn('TableUtils:push() ignored: the table is already destroyed (:destroy())');
		return;
	end;
	if value==nil then
		warn('TableUtils:push() ignored: attempted to add a nil value to the table');
		return;
	end;
	self._last = self._last + 1;
	self._list[self._last]=value;
	self:_notify(value);
	--self:_run()
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
	if type(position)~='number' then
		warn('TableUtils:removeAt() waits a number as index, but received:', tostring(position));
		return nil;
	end;
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
	if targetValue==nil then
		return nil;
	end;
	for i=self._first,self._last do
		if self._list[i]==targetValue then
			local relativePosition=(i-self._first)+1;
			return self:removeAt(relativePosition);
		end;
	end;
	return nil;
end;
function TableUtils:clear()
	self:stopProcess();
	self._list={};
	self._first=1;
	self._last=0;
	return true;
end;
function TableUtils:isEmpty()
	return self._first>self._last;
end;
function TableUtils:size()
	return (self._last-self._first)+1;
end;
function TableUtils:onPush(callback)
	if type(callback) ~= 'function' then
		warn('TableUtils:onPush() waits a function as argument, received:', tostring(callback));
		return;
	end;
	table.insert(self._listeners,callback);
end;
function TableUtils:_notify(item)
	for _,listener in ipairs(self._listeners) do
		local success,err=pcall(listener,item,self:size());
		if not success then
			warn('Error ocurred on a listener while running onPush:', err);
		end;
	end;
end;
function TableUtils:peek()
	if self:isEmpty() then return nil end
	return self._list[self._first]
end
function TableUtils:_run()
	if self._isProcessing or not self._handler or self:isEmpty() or self:isDestroyed() then 
		return 
	end
	self._isProcessing=true
	task.spawn(function()
		while not self:isEmpty() and self._isProcessing and not self:isDestroyed() do
			local currentIndex=self._first
			local currentItem=self:peek()
			local success,result=pcall(self._handler,currentItem,currentIndex)
			if success and result==true then
				self:pop()
			else
				if not success then
					print('Cannot proccess item:', result)
				end
				task.wait() 
			end
		end

		self._isProcessing=false
	end)
end

function TableUtils:stopProcess()
	self._isProcessing=false;
end

function TableUtils:process(handlerFunc)
	if type(handlerFunc) ~= "function" then
		print('TableUtils:process() waits a function as argument, received:', tostring(handlerFunc));
		return;
	end;
	self._handler = handlerFunc
	self:_run()
end

function TableUtils:loopWhileExists(callback, interval)
	if type(callback) ~= "function" then
		print('TableUtils:loopWhileExists() waits a function as argument, received:', tostring(callback));
		return;
	end;
	interval = interval or 0;
	if type(interval) ~= "number" or interval < 0 then
		print('TableUtils:loopWhileExists() received an invalid interval, using 0');
		interval = 0;
	end;
	task.spawn(function()
		while not self:isDestroyed() do
			local success,err=pcall(callback,self);
			if not success then
				warn('Error while runningloopWhileExists:', err);
			end;
			task.wait(interval);
		end;
	end);
end

function TableUtils:isDestroyed()
	return self._destroyed==true;
end

function TableUtils:destroy()
	if self:isDestroyed() then
		return;
	end;
	self:clear();
	self._listeners={};
	self._handler=nil;
	self._destroyed=true;
end

return TableUtils;
