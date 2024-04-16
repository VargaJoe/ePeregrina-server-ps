function BinaryHandler($requestObject) {
    $binary = [BinaryHandler]::new($this)
    $binary.GetPhysicalFile($requestObject)
}

function VirtualBinaryHandler($requestObject) {
    $binary = [BinaryHandler]::new($this)
    $binary.GetVirtualFile($this)
}
