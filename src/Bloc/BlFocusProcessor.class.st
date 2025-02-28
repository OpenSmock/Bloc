Class {
	#name : #BlFocusProcessor,
	#superclass : #BlBaseEventProcessor,
	#instVars : [
		'focusChain'
	],
	#category : #'Bloc-Space - Events'
}

{ #category : #'event firing' }
BlFocusProcessor >> fireBlurEvent: anElement [
	"Create and send blur event that doesn't bubble, perform simple direct dispatch to the given target element"
	self
		dispatchEvent: (self newBlurEvent target: anElement)
		target: anElement
]

{ #category : #'event firing' }
BlFocusProcessor >> fireBlurEvent: anElement dueTo: aFocusReason [
	"Create and send blur event that doesn't bubble, perform simple direct dispatch to the given target element"
	self
		dispatchEvent: (self newBlurEvent target: anElement; reason: aFocusReason)
		target: anElement
]

{ #category : #'event firing' }
BlFocusProcessor >> fireFocusEvent: anElement [
	"Send focus event that doesn't bubble, perform simple direct dispatch to the target"
	
	self
		dispatchEvent: (self newFocusEvent target: anElement)
		target: anElement
]

{ #category : #'event firing' }
BlFocusProcessor >> fireFocusInEvent: anElement [
	"Send focusIn event that should bubble"

	self fireEvent: (self newFocusInEvent target: anElement)
]

{ #category : #'event firing' }
BlFocusProcessor >> fireFocusInEvent: anElement from: aTopEventTarget [
	"Send focusIn event that should bubble"
	
	anElement == aTopEventTarget
		ifTrue: [ ^ self ].
	
	self fireEvent: (self newFocusInEvent target: anElement) from: aTopEventTarget
]

{ #category : #'event firing' }
BlFocusProcessor >> fireFocusOutEvent: anElement [
	"Send focusOut event that should bubble"

	self fireEvent: (self newFocusOutEvent target: anElement)
]

{ #category : #'event firing' }
BlFocusProcessor >> fireFocusOutEvent: anElement dueTo: aFocusReason [
	"Send focusOut event that should bubble"

	self fireEvent: (self newFocusOutEvent target: anElement; reason: aFocusReason)
]

{ #category : #'event firing' }
BlFocusProcessor >> fireFocusOutEvent: anElement from: aTopEventTarget dueTo: aFocusReason [
	"Send focusOut event that should bubble"

	self fireEvent: (self newFocusOutEvent target: anElement; reason: aFocusReason) from: aTopEventTarget
]

{ #category : #'event firing' }
BlFocusProcessor >> fireFocusTransferEvent: anElement from: aPreviousFocusedElement [
	"Send focus event that doesn't bubble, perform simple direct dispatch to the target"

	self
		dispatchEvent:
			(self newFocusTransferEvent
				 target: anElement;
				 transfer: aPreviousFocusedElement;
				 yourself)
		target: anElement
]

{ #category : #accessing }
BlFocusProcessor >> focusOwner [

	^ self space focusOwner
]

{ #category : #accessing }
BlFocusProcessor >> focusOwner: anElement [

	self space focusOwner: anElement
]

{ #category : #'focus - processing' }
BlFocusProcessor >> handleMouseDown: anEvent [
	"Clicking outside does not mean focus should be lost"
]

{ #category : #testing }
BlFocusProcessor >> hasFocusOwner [
	"Return true if there is an element holding focus, false otherwise.
	When there are no elements interested in focus it is given to the root element.
	Note: focus owner may not exist during space initialization or inbetween blur and focus events"

	^ self focusOwner notNil
]

{ #category : #'focus - requesting' }
BlFocusProcessor >> loseFor: anElement [

	| focusHolder |
	focusHolder := anElement focusHolder.
	self focusOwner ~= focusHolder ifTrue: [ ^ self ].

	self processBlur: focusHolder.
	"don't forget to forget focused element"
	self focusOwner: nil
]

{ #category : #'instance creation' }
BlFocusProcessor >> newBlurEvent [
	"Create, initialize and return a blur event that should be sent to the element
	that just lost its focus"

	^ BlBlurEvent new
		  canBePropagated: false;
		  yourself
]

{ #category : #'instance creation' }
BlFocusProcessor >> newFocusEvent [
	"Create, initialize and return a focus event that should be sent to the element
	after it gets focus"

	^ BlFocusEvent new
		  canBePropagated: false;
		  yourself
]

{ #category : #'instance creation' }
BlFocusProcessor >> newFocusInEvent [
	"Create, initialize and return a focus-in event that should be sent
	as a part of focus processing"
	
	^ BlFocusInEvent new
]

{ #category : #'instance creation' }
BlFocusProcessor >> newFocusOutEvent [
	"Create, initialize and return a focus-out event that should be sent
	as a part of blur processing"
	
	^ BlFocusOutEvent new
]

{ #category : #'instance creation' }
BlFocusProcessor >> newFocusTransferEvent [
	"Create, initialize and return a focus transfer event that should be sent to the element
	before performing a focus transfer"

	^ BlFocusTransferEvent new
]

{ #category : #'initialize-release' }
BlFocusProcessor >> onSpaceClosed [
	self focusOwner: nil.
	focusChain := nil
]

{ #category : #'focus - processing' }
BlFocusProcessor >> processBlur: anElement [
	self
		assert: [ self hasFocusOwner ]
		description: [ 'Blur event can only be processed when there is a focused element' ].

	"First make a given element to loose focus, then send events"
	self space focusOwner: nil.
	anElement focused: false.
	focusChain leafsDo: [ :aLeafElement | self fireFocusOutEvent: aLeafElement ].
	self fireBlurEvent: anElement
]

{ #category : #'focus - processing' }
BlFocusProcessor >> processBlur: anElement dueToFocus: aNewFocusedElement dueTo: aFocusReason [
	self
		assert: [ self hasFocusOwner ]
		description: [ 'Blur event can only be processed when there is a focused element' ].

	"First make a given element to loose focus, then send events"
	self space focusOwner: nil.
	anElement focused: false.

	focusChain leafsDo: [ :aLeafElement |
		"if a new focused element is a child we don't have to send focus-out event"
		(aNewFocusedElement hasParent: aLeafElement)
			ifFalse: [
				aLeafElement
					firstCommonParent: aNewFocusedElement
					ifFound: [ :aCommonParent | self fireFocusOutEvent: aLeafElement from: aCommonParent dueTo: aFocusReason ]
					ifNone: [ self fireFocusOutEvent: aLeafElement dueTo: aFocusReason ] ] ].

	self fireBlurEvent: anElement dueTo: aFocusReason
]

{ #category : #'focus - processing' }
BlFocusProcessor >> processFocus: anElement [
	self
		assert: [ anElement isNotNil ]
		description: [ 'Can not give focus to nil' ].
	self
		assert: [ anElement ~= self focusOwner ]
		description: [ 'Can not give focus to the already focused element' ].

	"first make element to be focused"
	self focusOwner: anElement.
	focusChain := BlFocusChain of: self focusOwner.
	anElement focused: true.

	"then send events"
	self fireFocusInEvent: anElement.
	self fireFocusEvent: anElement
]

{ #category : #'focus - processing' }
BlFocusProcessor >> processFocus: anElement dueToTransferFrom: aPreviousFocus [
	self
		assert: [ anElement isNotNil ]
		description: [ 'Can not give focus to nil' ].
	self
		assert: [ anElement ~= self focusOwner ]
		description: [ 'Can not give focus to the already focused element' ].

	"first make element to be focused"
	self focusOwner: anElement.
	focusChain := BlFocusChain of: self focusOwner.
	anElement focused: true.

	"then send events"	
	focusChain leafsDo: [ :aLeafElement |
		"if a new focused element is a child we don't have to send focus-in event"
		(aLeafElement hasParent: aPreviousFocus)
			ifFalse: [
				aLeafElement
					firstCommonParent: aPreviousFocus
					ifFound: [ :aCommonParent | self fireFocusInEvent: aLeafElement from: aCommonParent ]
					ifNone: [ self fireFocusInEvent: aLeafElement ] ]
			ifTrue: [ self fireFocusInEvent: aLeafElement from: aPreviousFocus ] ].
	
	self fireFocusEvent: anElement
]

{ #category : #'focus - processing' }
BlFocusProcessor >> processWindowFocusIn: anEvent [

	self space grabFocus
]

{ #category : #'focus - processing' }
BlFocusProcessor >> processWindowFocusOut: anEvent [

	self space ungrabFocus
]

{ #category : #'focus - requesting' }
BlFocusProcessor >> requestFor: anElement dueTo: aFocusReason [
	| aPreviousFocusOwner focusHolder |

	focusHolder := anElement focusHolder.
	self focusOwner = focusHolder
		ifTrue: [ ^ self ].

	focusHolder isFocusable
		ifFalse: [ ^ self ].

	"keep reference to the previous focus owner"
	aPreviousFocusOwner := self focusOwner.

	"we should only process blur event when there is focused element, otherwise skip it"
	self hasFocusOwner
		ifTrue: [ self processBlur: aPreviousFocusOwner dueToFocus: anElement dueTo: aFocusReason ].

	self focusOwner: nil.
	"focus is processed with new requested focus owner"
	aPreviousFocusOwner
		ifNil: [ self processFocus: focusHolder ]
		ifNotNil: [ self processFocus: focusHolder dueToTransferFrom: aPreviousFocusOwner ]
]
