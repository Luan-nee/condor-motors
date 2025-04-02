import { getFiles } from '@/core/controllers/archivos.controller'
import { FileCard } from './FileCard'
import { createSignal, onMount } from 'solid-js'
import type { FileEntity } from '@/types/archivos'
import { BubbleLoadingIcon } from './icons/BubbleLoadingIcon'

export const FileList = () => {
  const [files, setFiles] = createSignal<FileEntity[] | null>(null)
  const [error, setError] = createSignal<string | null>(null)

  onMount(async () => {
    const { data: apiData, error: apiError } = await getFiles()

    if (apiError != null) {
      setError(apiError.message)
      return
    }

    setFiles(apiData)
  })

  return (
    <>
      {error() != null && error()}
      {files() != null && files()?.map((item) => <FileCard file={item} />)}
      {files() == null && (
        <div class="flex flex-col justify-center items-center gap-4 h-full text-white/70">
          <BubbleLoadingIcon class="w-8 h-8" />
          <p>Loading files</p>
        </div>
      )}
    </>
  )
}
